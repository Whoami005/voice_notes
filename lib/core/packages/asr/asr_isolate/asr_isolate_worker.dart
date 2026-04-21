import 'dart:async';
import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_commands.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_engine.dart';

/// Точка входа фонового изолята для ASR.
void startAsrWorker(SendPort mainPort) => _AsrWorker(mainPort)..run();

/// Worker изолята для ASR транскрибации.
///
/// Делегирует вся model-specific логику на [AsrEngine] — сам держит только
/// command-routing, busy-guard и трекинг cancel'ов. Engine создаётся в
/// [InitializeCommand] через [AsrEngineFactory] и живёт до следующего
/// [InitializeCommand] или [DisposeCommand].
class _AsrWorker {
  final SendPort _responses;
  final ReceivePort _commands = ReceivePort();

  AsrEngine? _engine;

  /// ID активной in-flight задачи. `null` если воркер простаивает. Один
  /// движок одновременно обрабатывает не более одной
  /// [TranscribeCommand] / [TranscribeAudioCommand].
  int? _activeRequestId;

  /// ID'ы задач, отменённых через [CancelTranscribeCommand]. Streaming-
  /// engine проверяет это множество через `isCancelled()` между чанками.
  final Set<int> _cancelledRequestIds = {};

  bool _bindingsInitialized = false;

  _AsrWorker(this._responses);

  /// Запускает обработку команд от main isolate.
  void run() {
    _responses.send(_commands.sendPort);
    _commands.listen(_handleMessage);
  }

  void _handleMessage(dynamic message) {
    if (message is! AsrCommand) return;

    switch (message) {
      case InitializeCommand():
        _handleInitialize(message);
      case TranscribeCommand():
        _handleTranscribe(message);
      case TranscribeAudioCommand():
        _handleTranscribeAudio(message);
      case CancelTranscribeCommand():
        _handleCancelTranscribe(message);
      case DisposeCommand():
        _handleDispose();
    }
  }

  void _handleInitialize(InitializeCommand cmd) {
    try {
      _initBindingsIfNeeded();
      _engine?.dispose();
      _engine = AsrEngineFactory.build(cmd);
      _responses.send(const InitializeOkResponse());
    } catch (e) {
      _responses.send(InitializeFailedResponse('Init failed: $e'));
    }
  }

  void _handleTranscribe(TranscribeCommand cmd) {
    final engine = _engine;
    if (engine == null) {
      _responses.send(
        TranscribeFailedResponse(cmd.requestId, 'Recognizer not initialized'),
      );
      return;
    }

    if (_activeRequestId != null) {
      _responses.send(TranscribeBusyResponse(cmd.requestId));
      return;
    }

    _activeRequestId = cmd.requestId;
    unawaited(_runTranscribeFile(engine, cmd));
  }

  Future<void> _runTranscribeFile(
    AsrEngine engine,
    TranscribeCommand cmd,
  ) async {
    try {
      final result = await engine.transcribeFile(
        cmd.filePath,
        onProgress: (event) {
          _responses.send(
            TranscribeProgressResponse(
              requestId: cmd.requestId,
              progress: event.progress,
              partialText: event.partialText,
              processedSeconds: event.processedSeconds,
              totalSeconds: event.totalSeconds,
            ),
          );
        },
        isCancelled: () => _cancelledRequestIds.contains(cmd.requestId),
      );

      switch (result) {
        case AsrEngineOk(:final result):
          _responses.send(TranscribeOkResponse(cmd.requestId, result));
        case AsrEngineCancelled():
          _responses.send(TranscribeCancelledResponse(cmd.requestId));
      }
    } catch (e) {
      _responses.send(
        TranscribeFailedResponse(cmd.requestId, 'Transcription failed: $e'),
      );
    } finally {
      _activeRequestId = null;
      _cancelledRequestIds.remove(cmd.requestId);
    }
  }

  void _handleTranscribeAudio(TranscribeAudioCommand cmd) {
    final engine = _engine;
    if (engine == null) {
      _responses.send(
        TranscribeFailedResponse(cmd.requestId, 'Recognizer not initialized'),
      );
      return;
    }

    if (!engine.supportsAudioBuffer) {
      _responses.send(
        TranscribeFailedResponse(
          cmd.requestId,
          'transcribeAudio not supported on this recognizer',
        ),
      );
      return;
    }

    if (_activeRequestId != null) {
      _responses.send(TranscribeBusyResponse(cmd.requestId));
      return;
    }

    _activeRequestId = cmd.requestId;

    try {
      final result = engine.transcribeBuffer(cmd.samples, cmd.sampleRate);
      _responses.send(TranscribeOkResponse(cmd.requestId, result));
    } catch (e) {
      _responses.send(
        TranscribeFailedResponse(cmd.requestId, 'Transcription failed: $e'),
      );
    } finally {
      _activeRequestId = null;
    }
  }

  void _handleCancelTranscribe(CancelTranscribeCommand cmd) {
    final engine = _engine;
    if (engine == null || !engine.supportsCancellation) {
      developer.log(
        'CancelTranscribeCommand ignored for request ${cmd.requestId}: '
        'engine does not support cancellation',
        name: 'AsrIsolateWorker',
      );
      return;
    }
    _cancelledRequestIds.add(cmd.requestId);
  }

  void _handleDispose() {
    _engine?.dispose();
    _engine = null;
    _responses.send(#exit);
    _commands.close();
  }

  void _initBindingsIfNeeded() {
    if (_bindingsInitialized) return;

    sherpa.initBindings();
    _bindingsInitialized = true;
  }
}
