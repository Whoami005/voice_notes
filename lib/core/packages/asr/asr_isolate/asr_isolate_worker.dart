import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:voice_notes/core/packages/asr/asr_config.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_commands.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Точка входа фонового изолята для ASR.
///
/// Создаёт worker и запускает обработку команд.
/// Вызывается через `Isolate.spawn` из AsrIsolateRunner.
void startAsrWorker(SendPort mainPort) => _AsrWorker(mainPort)..run();

/// Worker изолята для офлайн ASR транскрибации.
///
/// Владеет собственным [sherpa.OfflineRecognizer], который живёт
/// до получения [DisposeCommand]. Это позволяет избежать повторной
/// загрузки модели при каждой транскрибации.
class _AsrWorker {
  final SendPort _responses;
  final ReceivePort _commands = ReceivePort();

  sherpa.OfflineRecognizer? _recognizer;
  bool _bindingsInitialized = false;

  _AsrWorker(this._responses);

  /// Запускает обработку команд от main isolate.
  void run() {
    // Отправляем свой SendPort для получения команд
    _responses.send(_commands.sendPort);

    _commands.listen(_handleMessage);
  }

  /// Роутер команд.
  void _handleMessage(dynamic message) {
    if (message is! AsrCommand) return;

    switch (message) {
      case InitializeCommand():
        _handleInitialize(message);
      case TranscribeCommand():
        _handleTranscribe(message);
      case TranscribeAudioCommand():
        _handleTranscribeAudio(message);
      case DisposeCommand():
        _handleDispose();
    }
  }

  /// Инициализирует recognizer с указанной моделью.
  void _handleInitialize(InitializeCommand cmd) {
    try {
      _initBindingsIfNeeded();

      final config = _createConfig(cmd.modelType, cmd.modelPath, cmd.fileNames);
      _recognizer = _createRecognizer(config);

      _responses.send(const InitializeResponse.ok());
    } catch (e) {
      _responses.send(InitializeResponse.failed('Init failed: $e'));
    }
  }

  /// Транскрибирует WAV файл и отправляет результат.
  void _handleTranscribe(TranscribeCommand cmd) {
    if (_recognizer == null) {
      _responses.send(
        TranscribeResponse.failed(cmd.requestId, 'Recognizer not initialized'),
      );
      return;
    }

    try {
      final result = _transcribeFile(cmd.filePath);
      _responses.send(TranscribeResponse.ok(cmd.requestId, result));
    } catch (e) {
      _responses.send(
        TranscribeResponse.failed(cmd.requestId, 'Transcription failed: $e'),
      );
    }
  }

  /// Транскрибирует аудио буфер и отправляет результат.
  void _handleTranscribeAudio(TranscribeAudioCommand cmd) {
    if (_recognizer == null) {
      _responses.send(
        TranscribeResponse.failed(cmd.requestId, 'Recognizer not initialized'),
      );
      return;
    }

    try {
      final samples = Float32List.fromList(cmd.samples);
      final result = _transcribeAudio(samples, cmd.sampleRate);
      _responses.send(TranscribeResponse.ok(cmd.requestId, result));
    } catch (e) {
      _responses.send(
        TranscribeResponse.failed(cmd.requestId, 'Transcription failed: $e'),
      );
    }
  }

  /// Освобождает ресурсы и закрывает порт.
  void _handleDispose() {
    _recognizer?.free();
    _recognizer = null;
    _responses.send(#exit); // Уведомляем main isolate о завершении
    _commands.close();
  }

  // ===========================================================================
  // Приватные методы
  // ===========================================================================

  void _initBindingsIfNeeded() {
    if (!_bindingsInitialized) {
      sherpa.initBindings();
      _bindingsInitialized = true;
    }
  }

  /// Выполняет транскрибацию файла.
  AsrResult _transcribeFile(String filePath) {
    final stopwatch = Stopwatch()..start();

    final waveData = sherpa.readWave(filePath);

    final stream = _recognizer!.createStream()
      ..acceptWaveform(
        samples: waveData.samples,
        sampleRate: waveData.sampleRate,
      );

    _recognizer!.decode(stream);
    final result = _recognizer!.getResult(stream);

    stream.free();
    stopwatch.stop();

    return AsrResult(
      text: result.text.trim(),
      tokens: result.tokens,
      timestamps: result.timestamps,
      detectedLanguage: result.lang.isNotEmpty ? result.lang : null,
      processingTime: stopwatch.elapsed,
    );
  }

  /// Выполняет транскрибацию аудио буфера.
  AsrResult _transcribeAudio(Float32List samples, int sampleRate) {
    final stopwatch = Stopwatch()..start();

    final stream = _recognizer!.createStream()
      ..acceptWaveform(samples: samples, sampleRate: sampleRate);

    _recognizer!.decode(stream);
    final result = _recognizer!.getResult(stream);

    stream.free();
    stopwatch.stop();

    return AsrResult(
      text: result.text.trim(),
      tokens: result.tokens,
      timestamps: result.timestamps,
      detectedLanguage: result.lang.isNotEmpty ? result.lang : null,
      processingTime: stopwatch.elapsed,
    );
  }

  /// Создаёт конфигурацию модели по типу.
  AsrModelConfig _createConfig(
    AsrModelType modelType,
    String modelPath,
    Map<String, String> fileNames,
  ) {
    return switch (modelType) {
      AsrModelType.whisper => WhisperAsrConfig(
        encoderPath: '$modelPath/${fileNames['encoder']}',
        decoderPath: '$modelPath/${fileNames['decoder']}',
        tokensPath: '$modelPath/${fileNames['tokens']}',
      ),
      AsrModelType.parakeetTdt => TransducerAsrConfig(
        encoderPath: '$modelPath/${fileNames['encoder']}',
        decoderPath: '$modelPath/${fileNames['decoder']}',
        joinerPath: '$modelPath/${fileNames['joiner']}',
        tokensPath: '$modelPath/${fileNames['tokens']}',
      ),
    };
  }

  /// Создаёт offline recognizer для конфигурации.
  sherpa.OfflineRecognizer _createRecognizer(AsrModelConfig config) {
    final sherpaConfig = switch (config) {
      WhisperAsrConfig() => sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: config.encoderPath,
            decoder: config.decoderPath,
            language: config.language ?? '',
            task: config.task,
            tailPaddings: config.tailPaddings,
          ),
          tokens: config.tokensPath,
          numThreads: config.numThreads,
        ),
      ),
      TransducerAsrConfig() => sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          transducer: sherpa.OfflineTransducerModelConfig(
            encoder: config.encoderPath,
            decoder: config.decoderPath,
            joiner: config.joinerPath,
          ),
          tokens: config.tokensPath,
          numThreads: config.numThreads,
        ),
      ),
    };

    return sherpa.OfflineRecognizer(sherpaConfig);
  }
}
