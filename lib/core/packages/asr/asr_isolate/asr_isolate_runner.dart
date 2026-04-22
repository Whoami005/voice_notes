import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_commands.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_isolate_worker.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_plan.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Внутреннее представление in-flight [TranscribeCommand] на main-стороне.
///
/// Присутствие записи в [AsrIsolateRunner._pendingRequests] = запрос
/// ещё in-flight. Удаление = терминальный исход (ok/cancelled/failed/busy)
/// или `close()`. Поздний `cancelToken.cancel()` проверяет членство в карте
/// и не шлёт stale [CancelTranscribeCommand].
class _PendingRequest {
  _PendingRequest(this.completer, this.onProgress);

  final Completer<AsrResult> completer;
  final void Function(AsrTranscribeProgress progress)? onProgress;
}

/// Управляет фоновым изолятом для офлайн/стриминг ASR транскрибации.
///
/// Изолят создаётся при вызове [spawn] и живёт до [close].
/// Это позволяет избежать повторной загрузки модели (~500ms-2s)
/// при каждой транскрибации.
///
/// Протокол isolate — one-to-many: один [TranscribeCommand] →
/// N × [TranscribeProgressResponse] + один из терминальных
/// [TranscribeOkResponse] / [TranscribeCancelledResponse] /
/// [TranscribeBusyResponse] / [TranscribeFailedResponse].
class AsrIsolateRunner {
  final ReceivePort _responses;
  final SendPort _commands;

  /// Ожидающие ответа запросы: requestId → запись с completer + onProgress.
  final Map<int, _PendingRequest> _pendingRequests = {};

  /// Счётчик для генерации уникальных ID запросов.
  int _requestId = 0;

  /// Completer для ожидания инициализации модели. `complete()` на успех,
  /// `completeError(...)` на [InitializeFailedResponse].
  Completer<void>? _pendingInitialization;

  /// Флаг закрытия runner'а.
  bool _isClosed = false;

  AsrIsolateRunner._(this._responses, this._commands) {
    _responses.listen(_handleResponse);
  }

  /// Запущен ли изолят и готов ли принимать команды.
  bool get isRunning => !_isClosed;

  /// Создаёт и запускает фоновый изолят.
  ///
  /// После вызова изолят готов принимать команды через [initialize]
  /// и [transcribeFile].
  static Future<AsrIsolateRunner> spawn() async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();

    initPort.handler = (dynamic message) {
      final commandPort = message as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    try {
      await Isolate.spawn(
        startAsrWorker,
        initPort.sendPort,
        debugName: 'AsrWorker',
      );
    } on Object {
      initPort.close();
      rethrow;
    }

    final (responses, commands) = await connection.future;
    return AsrIsolateRunner._(responses, commands);
  }

  /// Тест-only конструктор для юнит-тестов с fake-worker'ом.
  ///
  /// Позволяет подставить in-memory [SendPort]/[ReceivePort] pair вместо
  /// реального `Isolate.spawn`, чтобы тестировать protocol-логику runner'а
  /// без FFI и native recognizer'а.
  @visibleForTesting
  factory AsrIsolateRunner.forTesting({
    required ReceivePort responses,
    required SendPort commands,
  }) => AsrIsolateRunner._(responses, commands);

  /// Инициализирует модель в изоляте.
  Future<void> initialize(AsrModelEntity model, String modelPath) async {
    _ensureRunning();

    final completer = Completer<void>.sync();
    _pendingInitialization = completer;

    _commands.send(
      InitializeCommand(
        modelType: model.modelType,
        modelPath: modelPath,
        files: model.getModelFiles(),
        sherpaModelType: model.sherpaModelType,
      ),
    );

    try {
      await completer.future;
    } finally {
      _pendingInitialization = null;
    }
  }

  /// Транскрибирует WAV файл в фоновом изоляте.
  ///
  /// [onProgress] вызывается для каждого [TranscribeProgressResponse].
  /// Для `singlePass` не вызывается.
  ///
  /// [cancelToken] при `cancel()` отправляет [CancelTranscribeCommand].
  /// Для interactive-стратегий это прерывает задачу между чанками.
  Future<AsrResult> transcribeFile(
    String filePath, {
    AsrTranscriptionPlan transcriptionPlan =
        const AsrTranscriptionPlan.streaming(),
    void Function(AsrTranscribeProgress progress)? onProgress,
    AsrCancelToken? cancelToken,
  }) => _submitTranscribe(
    (id) => TranscribeCommand(
      requestId: id,
      filePath: filePath,
      transcriptionPlan: transcriptionPlan,
    ),
    onProgress: onProgress,
    cancelToken: cancelToken,
  );

  /// Транскрибирует аудио буфер в фоновом изоляте.
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate) =>
      _submitTranscribe(
        (id) => TranscribeAudioCommand(
          requestId: id,
          samples: samples,
          sampleRate: sampleRate,
        ),
      );

  /// Общий скелет отправки `Transcribe*Command`: alloc requestId →
  /// регистрация [_PendingRequest] → wiring cancel'а → send → вернуть future.
  Future<AsrResult> _submitTranscribe(
    AsrCommand Function(int requestId) makeCommand, {
    void Function(AsrTranscribeProgress progress)? onProgress,
    AsrCancelToken? cancelToken,
  }) {
    _ensureRunning();

    final requestId = _requestId++;
    final entry = _PendingRequest(Completer<AsrResult>.sync(), onProgress);
    _pendingRequests[requestId] = entry;

    if (cancelToken != null) {
      unawaited(
        cancelToken.whenCancelled.then((_) {
          if (_isClosed || !_pendingRequests.containsKey(requestId)) return;
          _commands.send(CancelTranscribeCommand(requestId));
        }),
      );
    }

    _commands.send(makeCommand(requestId));
    return entry.completer.future;
  }

  /// Завершает работу изолята и освобождает ресурсы.
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;

    _commands.send(const DisposeCommand());

    for (final entry in _pendingRequests.values) {
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(
          const AsrProcessingException('Runner was closed'),
        );
      }
    }
    _pendingRequests.clear();
  }

  // ===========================================================================
  // Приватные методы
  // ===========================================================================

  /// Обрабатывает сообщения от worker isolate. Exhaustive по
  /// [AsrResponse] sealed — компилятор ловит пропущенные ветки.
  void _handleResponse(dynamic message) {
    if (message == #exit) {
      _responses.close();
      return;
    }

    if (message is! AsrResponse) return;

    switch (message) {
      case InitializeOkResponse():
        _pendingInitialization?.complete();
      case InitializeFailedResponse(:final error):
        _pendingInitialization?.completeError(AsrProcessingException(error));
      case TranscribeProgressResponse():
        _dispatchProgress(message);
      case TranscribeOkResponse(:final requestId, :final result):
        _completeRequest(requestId, (c) => c.complete(result));
      case TranscribeCancelledResponse(:final requestId):
        _completeRequest(
          requestId,
          (c) => c.completeError(const AsrCancelledException()),
        );
      case TranscribeBusyResponse(:final requestId):
        _completeRequest(
          requestId,
          (c) => c.completeError(const AsrWorkerBusyException()),
        );
      case TranscribeFailedResponse(:final requestId, :final error):
        _completeRequest(
          requestId,
          (c) => c.completeError(AsrProcessingException(error)),
        );
    }
  }

  void _dispatchProgress(TranscribeProgressResponse message) {
    final entry = _pendingRequests[message.requestId];
    if (entry == null) return;

    entry.onProgress?.call(
      AsrTranscribeProgress(
        progress: message.progress,
        partialText: message.partialText,
        processedAudio: _secondsToDuration(message.processedSeconds),
        totalAudio: _secondsToDuration(message.totalSeconds),
        strategy: message.strategy,
        stage: message.stage,
        processedUnits: message.processedUnits,
        totalUnits: message.totalUnits,
      ),
    );
  }

  void _completeRequest(
    int requestId,
    void Function(Completer<AsrResult> completer) finish,
  ) {
    final entry = _pendingRequests.remove(requestId);
    if (entry == null) return;

    finish(entry.completer);
  }

  void _ensureRunning() {
    if (_isClosed) throw const AsrNotInitializedException();
  }

  static Duration _secondsToDuration(double seconds) {
    if (seconds <= 0) return Duration.zero;
    return Duration(microseconds: (seconds * 1000000).round());
  }
}
