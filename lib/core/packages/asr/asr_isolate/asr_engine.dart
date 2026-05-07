import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_commands.dart';
import 'package:voice_notes/core/packages/asr/asr_model_files.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_text_merge.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_plan.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_segment.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

const int _streamingChunkSamples = 3200;
const int _sampleRate = 16000;
const int _defaultNumThreads = 2;

typedef AsrProgressEvent = ({
  double progress,
  String partialText,
  double processedSeconds,
  double totalSeconds,
  AsrTranscriptionStrategy strategy,
  AsrTranscribeStage stage,
  int processedUnits,
  int totalUnits,
});

typedef AsrProgressSink = void Function(AsrProgressEvent event);

sealed class AsrEngineResult {
  const AsrEngineResult();
}

final class AsrEngineOk extends AsrEngineResult {
  final AsrResult result;

  const AsrEngineOk(this.result);
}

final class AsrEngineCancelled extends AsrEngineResult {
  const AsrEngineCancelled();
}

sealed class AsrEngine {
  bool get supportsAudioBuffer;

  Future<AsrEngineResult> transcribeFile(
    String filePath, {
    required AsrTranscriptionPlan plan,
    required AsrProgressSink onProgress,
    required bool Function() isCancelled,
  });

  AsrResult transcribeBuffer(Float32List samples, int sampleRate);

  void dispose();
}

final class OfflineAsrEngine extends AsrEngine {
  final sherpa.OfflineRecognizer _recognizer;

  OfflineAsrEngine(this._recognizer);

  @override
  bool get supportsAudioBuffer => true;

  @override
  Future<AsrEngineResult> transcribeFile(
    String filePath, {
    required AsrTranscriptionPlan plan,
    required AsrProgressSink onProgress,
    required bool Function() isCancelled,
  }) async {
    final waveData = sherpa.readWave(filePath);
    if (waveData.samples.isEmpty || waveData.sampleRate <= 0) {
      throw AsrInvalidAudioException('Failed to read WAV file: $filePath');
    }

    final audioDuration = plan.audioDuration == Duration.zero
        ? _samplesToDuration(waveData.samples.length, waveData.sampleRate)
        : plan.audioDuration;

    return switch (plan.strategy) {
      AsrTranscriptionStrategy.auto ||
      AsrTranscriptionStrategy.singlePass => AsrEngineOk(
        _decodeSinglePass(
          samples: waveData.samples,
          sampleRate: waveData.sampleRate,
          audioDuration: audioDuration,
        ),
      ),
      AsrTranscriptionStrategy.chunked => _decodeChunked(
        samples: waveData.samples,
        sampleRate: waveData.sampleRate,
        audioDuration: audioDuration,
        plan: plan,
        onProgress: onProgress,
        isCancelled: isCancelled,
      ),
      AsrTranscriptionStrategy.chunkedVad => _decodeChunkedVad(
        samples: waveData.samples,
        sampleRate: waveData.sampleRate,
        audioDuration: audioDuration,
        plan: plan,
        onProgress: onProgress,
        isCancelled: isCancelled,
      ),
      AsrTranscriptionStrategy.streaming => throw const AsrProcessingException(
        'Streaming plan is not supported on offline recognizer',
      ),
    };
  }

  @override
  AsrResult transcribeBuffer(Float32List samples, int sampleRate) {
    final audioDuration = _samplesToDuration(samples.length, sampleRate);
    return _decodeSinglePass(
      samples: samples,
      sampleRate: sampleRate,
      audioDuration: audioDuration,
    );
  }

  AsrResult _decodeSinglePass({
    required Float32List samples,
    required int sampleRate,
    required Duration audioDuration,
  }) {
    final result = _decode(samples, sampleRate);
    final segment = AsrTranscriptionSegment(
      text: result.text,
      start: Duration.zero,
      end: audioDuration,
      tokens: result.tokens,
      timestamps: result.timestamps,
      detectedLanguage: result.detectedLanguage,
    );

    return result.copyWith(
      strategyUsed: AsrTranscriptionStrategy.singlePass,
      audioDuration: audioDuration,
      segments: [segment],
      stats: const AsrTranscriptionStats(processedUnits: 1, totalUnits: 1),
    );
  }

  Future<AsrEngineResult> _decodeChunked({
    required Float32List samples,
    required int sampleRate,
    required Duration audioDuration,
    required AsrTranscriptionPlan plan,
    required AsrProgressSink onProgress,
    required bool Function() isCancelled,
    bool fellBackFromVad = false,
  }) async {
    final units = _buildChunkUnits(
      samples: samples,
      sampleRate: sampleRate,
      chunkDuration: plan.chunkDuration,
      chunkOverlap: plan.chunkOverlap,
    );

    return _decodeUnits(
      units: units,
      sampleRate: sampleRate,
      audioDuration: audioDuration,
      strategy: AsrTranscriptionStrategy.chunked,
      usedVad: false,
      fellBackFromVad: fellBackFromVad,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }

  Future<AsrEngineResult> _decodeChunkedVad({
    required Float32List samples,
    required int sampleRate,
    required Duration audioDuration,
    required AsrTranscriptionPlan plan,
    required AsrProgressSink onProgress,
    required bool Function() isCancelled,
  }) async {
    final vadConfig = plan.vadConfig;
    if (vadConfig == null || !vadConfig.isConfigured) {
      return _decodeChunked(
        samples: samples,
        sampleRate: sampleRate,
        audioDuration: audioDuration,
        plan: plan,
        onProgress: onProgress,
        isCancelled: isCancelled,
        fellBackFromVad: true,
      );
    }

    final sherpa.VoiceActivityDetector detector;
    try {
      detector = sherpa.VoiceActivityDetector(
        config: sherpa.VadModelConfig(
          sileroVad: sherpa.SileroVadModelConfig(
            model: vadConfig.modelPath,
            threshold: vadConfig.threshold,
            minSilenceDuration: _seconds(vadConfig.minSilenceDuration),
            minSpeechDuration: _seconds(vadConfig.minSpeechDuration),
            windowSize: vadConfig.windowSize,
            maxSpeechDuration: _seconds(vadConfig.maxSpeechDuration),
          ),
          sampleRate: sampleRate,
          debug: false,
        ),
        bufferSizeInSeconds: _seconds(vadConfig.bufferSize),
      );
    } catch (_) {
      return _decodeChunked(
        samples: samples,
        sampleRate: sampleRate,
        audioDuration: audioDuration,
        plan: plan,
        onProgress: onProgress,
        isCancelled: isCancelled,
        fellBackFromVad: true,
      );
    }

    try {
      final units = <_DecodeUnit>[];
      final windowSamples = math.max(vadConfig.windowSize, 1);
      final totalSamples = samples.length;
      int processed = 0;

      while (processed < totalSamples) {
        if (isCancelled()) return const AsrEngineCancelled();

        final end = math.min(processed + windowSamples, totalSamples);
        final chunk = Float32List.sublistView(samples, processed, end);
        detector.acceptWaveform(chunk);
        processed = end;

        _appendDetectedVadUnits(
          detector: detector,
          units: units,
          sampleRate: sampleRate,
          plan: plan,
        );

        onProgress((
          progress: _detectionProgress(processed, totalSamples),
          partialText: '',
          processedSeconds: processed / sampleRate,
          totalSeconds: totalSamples / sampleRate,
          strategy: AsrTranscriptionStrategy.chunkedVad,
          stage: AsrTranscribeStage.detectingSpeech,
          processedUnits: 0,
          totalUnits: 0,
        ));

        await Future<void>.delayed(Duration.zero);
      }

      detector.flush();
      _appendDetectedVadUnits(
        detector: detector,
        units: units,
        sampleRate: sampleRate,
        plan: plan,
      );

      if (units.isEmpty) {
        return AsrEngineOk(
          AsrResult(
            text: '',
            audioDuration: audioDuration,
            strategyUsed: AsrTranscriptionStrategy.chunkedVad,
            stats: const AsrTranscriptionStats(usedVad: true),
          ),
        );
      }

      return _decodeUnits(
        units: units,
        sampleRate: sampleRate,
        audioDuration: audioDuration,
        strategy: AsrTranscriptionStrategy.chunkedVad,
        usedVad: true,
        onProgress: onProgress,
        isCancelled: isCancelled,
        initialProgress: 0.1,
      );
    } finally {
      detector.free();
    }
  }

  Future<AsrEngineResult> _decodeUnits({
    required List<_DecodeUnit> units,
    required int sampleRate,
    required Duration audioDuration,
    required AsrTranscriptionStrategy strategy,
    required bool usedVad,
    required AsrProgressSink onProgress,
    required bool Function() isCancelled,
    bool fellBackFromVad = false,
    double initialProgress = 0,
  }) async {
    final stopwatch = Stopwatch()..start();
    final tokens = <String>[];
    final timestamps = <double>[];
    final segments = <AsrTranscriptionSegment>[];
    String? detectedLanguage;
    final _LabelFrequencyAggregator emotionAggregator =
        _LabelFrequencyAggregator();
    final _LabelFrequencyAggregator eventAggregator =
        _LabelFrequencyAggregator();
    String mergedText = '';
    int processedUnits = 0;
    final totalUnits = units.length;

    for (final unit in units) {
      if (isCancelled()) return const AsrEngineCancelled();

      final result = _decode(unit.samples, sampleRate);
      final shiftedTimestamps = _shiftTimestamps(result.timestamps, unit.start);
      final segment = AsrTranscriptionSegment(
        text: result.text,
        start: unit.start,
        end: unit.end,
        tokens: result.tokens,
        timestamps: shiftedTimestamps,
        detectedLanguage: result.detectedLanguage,
      );

      processedUnits++;

      if (segment.text.isNotEmpty) {
        segments.add(segment);
        tokens.addAll(result.tokens);
        timestamps.addAll(shiftedTimestamps);
        detectedLanguage ??= result.detectedLanguage;
        emotionAggregator.add(result.emotionLabel);
        eventAggregator.add(result.eventLabel);
        mergedText = AsrTextMerge.merge(mergedText, segment.text);
      }

      final unitProgress =
          initialProgress +
          ((1 - initialProgress) * processedUnits / totalUnits);
      onProgress((
        progress: unitProgress,
        partialText: mergedText,
        processedSeconds:
            unit.end.inMicroseconds / Duration.microsecondsPerSecond,
        totalSeconds:
            audioDuration.inMicroseconds / Duration.microsecondsPerSecond,
        strategy: strategy,
        stage: AsrTranscribeStage.decoding,
        processedUnits: processedUnits,
        totalUnits: totalUnits,
      ));

      await Future<void>.delayed(Duration.zero);
    }

    stopwatch.stop();

    return AsrEngineOk(
      AsrResult(
        text: mergedText.trim(),
        tokens: tokens,
        timestamps: timestamps,
        detectedLanguage: detectedLanguage,
        emotionLabel: emotionAggregator.resolve(),
        eventLabel: eventAggregator.resolve(),
        processingTime: stopwatch.elapsed,
        strategyUsed: strategy,
        audioDuration: audioDuration,
        segments: segments,
        stats: AsrTranscriptionStats(
          processedUnits: processedUnits,
          totalUnits: totalUnits,
          usedVad: usedVad,
          fellBackFromVad: fellBackFromVad,
        ),
      ),
    );
  }

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
        emotionLabel: result.emotion.isNotEmpty ? result.emotion : null,
        eventLabel: result.event.isNotEmpty ? result.event : null,
        processingTime: stopwatch.elapsed,
      );
    } finally {
      stream.free();
    }
  }

  List<_DecodeUnit> _buildChunkUnits({
    required Float32List samples,
    required int sampleRate,
    required Duration chunkDuration,
    required Duration chunkOverlap,
    int absoluteStartSample = 0,
  }) {
    final chunkSamples = _durationToSamples(chunkDuration, sampleRate);
    final overlapSamples = _durationToSamples(chunkOverlap, sampleRate);
    final step = math.max(chunkSamples - overlapSamples, 1);
    final units = <_DecodeUnit>[];
    int localStart = 0;

    while (localStart < samples.length) {
      final localEnd = math.min(localStart + chunkSamples, samples.length);
      final absoluteEnd = absoluteStartSample + localEnd;
      final absoluteStart = absoluteStartSample + localStart;

      units.add(
        _DecodeUnit(
          samples: Float32List.sublistView(samples, localStart, localEnd),
          start: _samplesToDuration(absoluteStart, sampleRate),
          end: _samplesToDuration(absoluteEnd, sampleRate),
        ),
      );

      if (localEnd == samples.length) break;
      localStart += step;
    }

    return units;
  }

  void _appendDetectedVadUnits({
    required sherpa.VoiceActivityDetector detector,
    required List<_DecodeUnit> units,
    required int sampleRate,
    required AsrTranscriptionPlan plan,
  }) {
    while (!detector.isEmpty()) {
      final segment = detector.front();
      detector.pop();

      units.addAll(
        _buildChunkUnits(
          samples: segment.samples,
          sampleRate: sampleRate,
          chunkDuration: plan.chunkDuration,
          chunkOverlap: plan.chunkOverlap,
          absoluteStartSample: segment.start,
        ),
      );
    }
  }

  @override
  void dispose() => _recognizer.free();
}

final class _LabelFrequencyAggregator {
  final Map<String, int> _counts = <String, int>{};
  final Map<String, String> _originalValues = <String, String>{};

  void add(String? rawLabel) {
    final String trimmedLabel = rawLabel?.trim() ?? '';
    if (trimmedLabel.isEmpty) return;

    final String normalizedLabel = trimmedLabel.toLowerCase();
    _counts[normalizedLabel] = (_counts[normalizedLabel] ?? 0) + 1;
    _originalValues.putIfAbsent(normalizedLabel, () => trimmedLabel);
  }

  String? resolve() {
    if (_counts.isEmpty) return null;

    String? winnerKey;
    int winnerCount = 0;
    bool hasTie = false;

    for (final MapEntry<String, int> entry in _counts.entries) {
      if (entry.value > winnerCount) {
        winnerKey = entry.key;
        winnerCount = entry.value;
        hasTie = false;
        continue;
      }

      if (entry.value == winnerCount) {
        hasTie = true;
      }
    }

    if (winnerKey == null || hasTie) return null;

    return _originalValues[winnerKey];
  }
}

final class StreamingAsrEngine extends AsrEngine {
  final sherpa.OnlineRecognizer _recognizer;

  StreamingAsrEngine(this._recognizer);

  @override
  bool get supportsAudioBuffer => false;

  @override
  Future<AsrEngineResult> transcribeFile(
    String filePath, {
    required AsrTranscriptionPlan plan,
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
      final totalUnits = (totalSamples / _streamingChunkSamples).ceil();
      stream = _recognizer.createStream();

      int processed = 0;
      int processedUnits = 0;
      String lastEmittedText = '';

      while (processed < totalSamples) {
        if (isCancelled()) return const AsrEngineCancelled();

        final end = math.min(processed + _streamingChunkSamples, totalSamples);
        final chunk = Float32List.sublistView(samples, processed, end);

        stream.acceptWaveform(samples: chunk, sampleRate: waveData.sampleRate);
        while (_recognizer.isReady(stream)) _recognizer.decode(stream);

        processed = end;
        processedUnits++;
        final partialText = _recognizer.getResult(stream).text;

        if (partialText != lastEmittedText || processed == totalSamples) {
          lastEmittedText = partialText;
          onProgress((
            progress: processed / totalSamples,
            partialText: partialText,
            processedSeconds: processed / _sampleRate,
            totalSeconds: totalSeconds,
            strategy: AsrTranscriptionStrategy.streaming,
            stage: AsrTranscribeStage.decoding,
            processedUnits: processedUnits,
            totalUnits: totalUnits,
          ));
        }

        await Future<void>.delayed(Duration.zero);
      }

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
          strategyUsed: AsrTranscriptionStrategy.streaming,
          audioDuration: _samplesToDuration(totalSamples, waveData.sampleRate),
          stats: AsrTranscriptionStats(
            processedUnits: processedUnits,
            totalUnits: totalUnits,
          ),
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

class _DecodeUnit {
  final Float32List samples;
  final Duration start;
  final Duration end;

  const _DecodeUnit({
    required this.samples,
    required this.start,
    required this.end,
  });
}

List<double> _shiftTimestamps(List<double> timestamps, Duration offset) {
  final offsetSeconds = offset.inMicroseconds / Duration.microsecondsPerSecond;
  return [for (final ts in timestamps) ts + offsetSeconds];
}

double _seconds(Duration value) =>
    value.inMicroseconds / Duration.microsecondsPerSecond;

Duration _samplesToDuration(int samples, int sampleRate) {
  return Duration(
    microseconds: (samples * Duration.microsecondsPerSecond / sampleRate)
        .round(),
  );
}

int _durationToSamples(Duration duration, int sampleRate) {
  return math.max(
    1,
    (duration.inMicroseconds * sampleRate / Duration.microsecondsPerSecond)
        .round(),
  );
}

double _detectionProgress(int processedSamples, int totalSamples) {
  if (totalSamples == 0) return 0;
  return (processedSamples / totalSamples) * 0.1;
}

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
