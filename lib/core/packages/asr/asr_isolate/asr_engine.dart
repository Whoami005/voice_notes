import 'dart:async';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_commands.dart';
import 'package:voice_notes/core/packages/asr/asr_model_files.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Размер чанка для streaming decode-loop (samples @ 16kHz ≈ 0.2 сек).
///
/// Баланс между latency cancel'а (≤ длина чанка) и overhead decode-вызовов.
/// Референс из sherpa C-API примера для online-recognizer'а — 3200 samples.
const int _streamingChunkSamples = 3200;

/// Частота дискретизации входных WAV-файлов. Все модели в каталоге
/// требуют 16kHz.
const int _sampleRate = 16000;

/// Дефолтное число потоков для native sherpa recognizer'а. Совпадает с
/// `AsrModelConfig.numThreads` (main-isolate streaming recognizer).
const int _defaultNumThreads = 2;

/// Событие прогресса streaming-engine'а. Воркер преобразует его в
/// [TranscribeProgressResponse]. Offline-engine'ы прогресс не эмитят.
typedef AsrProgressEvent = ({
  double progress,
  String partialText,
  double processedSeconds,
  double totalSeconds,
});

/// Коллбек прогресса streaming-engine'а.
typedef AsrProgressSink = void Function(AsrProgressEvent event);

/// Терминальный результат engine-уровня. Sealed — две опции вместо
/// flag'а "was cancelled" внутри результата. Failure'ы по-прежнему идут
/// через `throw` (воркер конвертирует в [TranscribeFailedResponse]).
sealed class AsrEngineResult {
  const AsrEngineResult();
}

/// Успешная транскрибация.
final class AsrEngineOk extends AsrEngineResult {
  final AsrResult result;

  const AsrEngineOk(this.result);
}

/// Транскрибация отменена кооперативным `isCancelled()` между чанками.
/// Возможно только для движков с `supportsCancellation == true`.
final class AsrEngineCancelled extends AsrEngineResult {
  const AsrEngineCancelled();
}

/// Sealed ASR engine — strategy per model-mode. Каждый движок владеет
/// своим sherpa recognizer'ом, декларирует свои capabilities и реализует
/// операции. Добавление нового режима (chunk+VAD и т.д.) = новый
/// подкласс + одна ветка в [AsrEngineFactory].
///
/// Используется только внутри worker-isolate'а. Публичная видимость — для
/// юнит-тестирования фабрики и полей capabilities (без FFI).
sealed class AsrEngine {
  /// Принимает ли движок `TranscribeAudioCommand` (raw buffer без WAV-файла).
  bool get supportsAudioBuffer;

  /// Поддерживает ли движок кооперативный cancel между чанками.
  bool get supportsCancellation;

  /// Декодирует WAV-файл. [onProgress] вызывается только у движков со
  /// streaming decode-loop'ом; [isCancelled] проверяется только у движков
  /// с `supportsCancellation == true`.
  Future<AsrEngineResult> transcribeFile(
    String filePath, {
    required AsrProgressSink onProgress,
    required bool Function() isCancelled,
  });

  /// Декодирует audio-buffer. Движок обязан бросить [UnsupportedError]
  /// если `supportsAudioBuffer == false` — воркер не должен вызывать
  /// этот метод, guard на уровне capability.
  AsrResult transcribeBuffer(Float32List samples, int sampleRate);

  void dispose();
}

/// Offline-движок для Whisper и Transducer-offline. Обе модели используют
/// `sherpa.OfflineRecognizer` — различие только в нативном конфиге,
/// логика декода идентична (один blocking `decode()`, ни progress,
/// ни cancel).
final class OfflineAsrEngine extends AsrEngine {
  final sherpa.OfflineRecognizer _recognizer;

  OfflineAsrEngine(this._recognizer);

  @override
  bool get supportsAudioBuffer => true;

  @override
  bool get supportsCancellation => false;

  @override
  Future<AsrEngineResult> transcribeFile(
    String filePath, {
    required AsrProgressSink onProgress,
    required bool Function() isCancelled,
  }) async {
    final waveData = sherpa.readWave(filePath);
    if (waveData.samples.isEmpty || waveData.sampleRate <= 0) {
      throw AsrInvalidAudioException('Failed to read WAV file: $filePath');
    }

    return AsrEngineOk(_decode(waveData.samples, waveData.sampleRate));
  }

  @override
  AsrResult transcribeBuffer(Float32List samples, int sampleRate) =>
      _decode(samples, sampleRate);

  AsrResult _decode(Float32List samples, int sampleRate) {
    final stopwatch = Stopwatch()..start();
    final stream = _recognizer.createStream()
      ..acceptWaveform(samples: samples, sampleRate: sampleRate);

    try {
      _recognizer.decode(stream);
      final result = _recognizer.getResult(stream);
      stopwatch.stop();

      return AsrResult(
        text: result.text.trim(),
        tokens: result.tokens,
        timestamps: result.timestamps,
        detectedLanguage: result.lang.isNotEmpty ? result.lang : null,
        processingTime: stopwatch.elapsed,
      );
    } finally {
      stream.free();
    }
  }

  @override
  void dispose() => _recognizer.free();
}

/// Streaming-движок для Transducer online (Parakeet TDT, Zipformer
/// streaming). Читает WAV, гонит чанки через `OnlineRecognizer`, эмитит
/// progress между чанками, проверяет cancel.
final class StreamingAsrEngine extends AsrEngine {
  final sherpa.OnlineRecognizer _recognizer;

  StreamingAsrEngine(this._recognizer);

  @override
  bool get supportsAudioBuffer => false;

  @override
  bool get supportsCancellation => true;

  @override
  Future<AsrEngineResult> transcribeFile(
    String filePath, {
    required AsrProgressSink onProgress,
    required bool Function() isCancelled,
  }) async {
    final stopwatch = Stopwatch()..start();
    sherpa.OnlineStream? stream;

    try {
      final waveData = sherpa.readWave(filePath);

      if (waveData.samples.isEmpty || waveData.sampleRate <= 0) {
        throw AsrInvalidAudioException('Failed to read WAV: $filePath');
      }

      final samples = waveData.samples;
      final totalSamples = samples.length;
      final totalSeconds = totalSamples / _sampleRate;
      stream = _recognizer.createStream();

      int processed = 0;
      String lastEmittedText = '';

      while (processed < totalSamples) {
        if (isCancelled()) return const AsrEngineCancelled();

        final end = (processed + _streamingChunkSamples).clamp(0, totalSamples);
        final chunk = Float32List.sublistView(samples, processed, end);

        stream.acceptWaveform(samples: chunk, sampleRate: waveData.sampleRate);
        while (_recognizer.isReady(stream)) _recognizer.decode(stream);

        processed = end;
        final partialText = _recognizer.getResult(stream).text;

        // Прогресс эмитим только на реальных изменениях partial-text'а
        // либо на финальном чанке — чтобы не насыщать port-канал
        // дубликатами между чанками при одном и том же распознанном тексте.
        if (partialText != lastEmittedText || processed == totalSamples) {
          lastEmittedText = partialText;
          onProgress((
            progress: processed / totalSamples,
            partialText: partialText,
            processedSeconds: processed / _sampleRate,
            totalSeconds: totalSeconds,
          ));
        }

        await Future<void>.delayed(Duration.zero);
      }

      // Финальный drain после inputFinished.
      stream.inputFinished();
      while (_recognizer.isReady(stream)) _recognizer.decode(stream);

      final finalResult = _recognizer.getResult(stream);
      stopwatch.stop();

      return AsrEngineOk(
        AsrResult(
          text: finalResult.text.trim(),
          tokens: finalResult.tokens,
          timestamps: finalResult.timestamps,
          processingTime: stopwatch.elapsed,
        ),
      );
    } finally {
      stream?.free();
    }
  }

  @override
  AsrResult transcribeBuffer(Float32List samples, int sampleRate) {
    throw UnsupportedError(
      'transcribeBuffer is not supported on streaming recognizer',
    );
  }

  @override
  void dispose() => _recognizer.free();
}

/// Фабрика движков. Exhaustive по [AsrModelType] — при добавлении нового
/// режима компилятор требует явно перечислить ветку.
///
/// Связь `modelType ↔ AsrModelFiles`-подкласс не гарантирована статически
/// (см. [AsrModelEntity.getModelFiles]), поэтому проверяется в runtime —
/// несоответствие означает баг в declaration'е модели и бросается как
/// [ArgumentError].
abstract final class AsrEngineFactory {
  static AsrEngine build(InitializeCommand cmd) {
    return switch (cmd.modelType) {
      AsrModelType.whisper => OfflineAsrEngine(
        _whisperRecognizer(cmd, _expect<WhisperModelFiles>(cmd)),
      ),
      AsrModelType.offlineTransducer => OfflineAsrEngine(
        _offlineTransducerRecognizer(cmd, _expect<TransducerModelFiles>(cmd)),
      ),
      AsrModelType.streamingTransducer => StreamingAsrEngine(
        _streamingTransducerRecognizer(cmd, _expect<TransducerModelFiles>(cmd)),
      ),
    };
  }

  /// Приводит [InitializeCommand.files] к ожидаемому подклассу
  /// [AsrModelFiles]. Рассогласование означает баг в declaration'е модели
  /// (см. [AsrModelEntity.getModelFiles]) и бросается как [ArgumentError].
  static T _expect<T extends AsrModelFiles>(InitializeCommand cmd) {
    final files = cmd.files;
    if (files is T) return files;

    throw ArgumentError(
      '${cmd.modelType} expects $T, got ${files.runtimeType}',
    );
  }

  static sherpa.OfflineRecognizer _whisperRecognizer(
    InitializeCommand cmd,
    WhisperModelFiles files,
  ) {
    return sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: '${cmd.modelPath}/${files.encoder}',
            decoder: '${cmd.modelPath}/${files.decoder}',
            // Транскрипция, а не перевод на английский. Остальные
            // параметры (language auto-detect, tailPaddings) наследуются
            // из дефолтов sherpa.
            task: 'transcribe',
          ),
          tokens: '${cmd.modelPath}/${files.tokens}',
          numThreads: _defaultNumThreads,
        ),
      ),
    );
  }

  static sherpa.OfflineRecognizer _offlineTransducerRecognizer(
    InitializeCommand cmd,
    TransducerModelFiles files,
  ) {
    return sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          transducer: sherpa.OfflineTransducerModelConfig(
            encoder: '${cmd.modelPath}/${files.encoder}',
            decoder: '${cmd.modelPath}/${files.decoder}',
            joiner: '${cmd.modelPath}/${files.joiner}',
          ),
          tokens: '${cmd.modelPath}/${files.tokens}',
          numThreads: _defaultNumThreads,
          modelType: cmd.sherpaModelType ?? '',
        ),
      ),
    );
  }

  static sherpa.OnlineRecognizer _streamingTransducerRecognizer(
    InitializeCommand cmd,
    TransducerModelFiles files,
  ) {
    return sherpa.OnlineRecognizer(
      sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: '${cmd.modelPath}/${files.encoder}',
            decoder: '${cmd.modelPath}/${files.decoder}',
            joiner: '${cmd.modelPath}/${files.joiner}',
          ),
          tokens: '${cmd.modelPath}/${files.tokens}',
          numThreads: _defaultNumThreads,
          modelType: cmd.sherpaModelType ?? '',
        ),
      ),
    );
  }
}
