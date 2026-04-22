import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';

class AsrVadConfig extends Equatable {
  final String modelPath;
  final double threshold;
  final Duration minSilenceDuration;
  final Duration minSpeechDuration;
  final Duration maxSpeechDuration;
  final Duration bufferSize;
  final int windowSize;

  const AsrVadConfig({
    required this.modelPath,
    this.threshold = 0.5,
    this.minSilenceDuration = const Duration(milliseconds: 450),
    this.minSpeechDuration = const Duration(milliseconds: 250),
    this.maxSpeechDuration = const Duration(seconds: 30),
    this.bufferSize = const Duration(seconds: 30),
    this.windowSize = 512,
  });

  bool get isConfigured => modelPath.isNotEmpty;

  @override
  List<Object?> get props => [
    modelPath,
    threshold,
    minSilenceDuration,
    minSpeechDuration,
    maxSpeechDuration,
    bufferSize,
    windowSize,
  ];
}

class AsrOfflineTranscriptionProfile extends Equatable {
  final Duration singlePassMaxAudio;
  final Duration singlePassMaxProcessingTime;
  final Duration chunkedMaxAudio;
  final Duration chunkDuration;
  final Duration chunkOverlap;
  final double estimatedRtf;
  final AsrVadConfig vadConfig;

  const AsrOfflineTranscriptionProfile({
    required this.singlePassMaxAudio,
    required this.singlePassMaxProcessingTime,
    required this.chunkedMaxAudio,
    required this.chunkDuration,
    required this.chunkOverlap,
    required this.estimatedRtf,
    this.vadConfig = const AsrVadConfig(modelPath: ''),
  });

  AsrOfflineTranscriptionProfile withVadModelPath(String? modelPath) {
    if (modelPath == null || modelPath.isEmpty) return this;

    return AsrOfflineTranscriptionProfile(
      singlePassMaxAudio: singlePassMaxAudio,
      singlePassMaxProcessingTime: singlePassMaxProcessingTime,
      chunkedMaxAudio: chunkedMaxAudio,
      chunkDuration: chunkDuration,
      chunkOverlap: chunkOverlap,
      estimatedRtf: estimatedRtf,
      vadConfig: AsrVadConfig(
        modelPath: modelPath,
        threshold: vadConfig.threshold,
        minSilenceDuration: vadConfig.minSilenceDuration,
        minSpeechDuration: vadConfig.minSpeechDuration,
        maxSpeechDuration: vadConfig.maxSpeechDuration,
        bufferSize: vadConfig.bufferSize,
        windowSize: vadConfig.windowSize,
      ),
    );
  }

  static const whisperTinyEn = AsrOfflineTranscriptionProfile(
    singlePassMaxAudio: Duration(minutes: 3),
    singlePassMaxProcessingTime: Duration(seconds: 20),
    chunkedMaxAudio: Duration(minutes: 5),
    chunkDuration: Duration(seconds: 30),
    chunkOverlap: Duration(seconds: 3),
    estimatedRtf: 0.12,
  );

  static const whisperSmall = AsrOfflineTranscriptionProfile(
    singlePassMaxAudio: Duration(seconds: 10),
    singlePassMaxProcessingTime: Duration(seconds: 22),
    chunkedMaxAudio: Duration(minutes: 5),
    chunkDuration: Duration(seconds: 30),
    chunkOverlap: Duration(seconds: 3),
    estimatedRtf: 0.18,
  );

  static const whisperMedium = AsrOfflineTranscriptionProfile(
    singlePassMaxAudio: Duration(seconds: 90),
    singlePassMaxProcessingTime: Duration(seconds: 25),
    chunkedMaxAudio: Duration(minutes: 5),
    chunkDuration: Duration(seconds: 30),
    chunkOverlap: Duration(seconds: 3),
    estimatedRtf: 0.28,
  );

  static const defaultOffline = AsrOfflineTranscriptionProfile(
    singlePassMaxAudio: Duration(minutes: 2),
    singlePassMaxProcessingTime: Duration(seconds: 20),
    chunkedMaxAudio: Duration(minutes: 5),
    chunkDuration: Duration(seconds: 30),
    chunkOverlap: Duration(seconds: 3),
    estimatedRtf: 0.16,
  );

  @override
  List<Object?> get props => [
    singlePassMaxAudio,
    singlePassMaxProcessingTime,
    chunkedMaxAudio,
    chunkDuration,
    chunkOverlap,
    estimatedRtf,
    vadConfig,
  ];
}

class AsrTranscriptionPlan extends Equatable {
  final AsrTranscriptionStrategy strategy;
  final Duration audioDuration;
  final Duration chunkDuration;
  final Duration chunkOverlap;
  final AsrVadConfig? vadConfig;

  const AsrTranscriptionPlan({
    required this.strategy,
    this.audioDuration = Duration.zero,
    this.chunkDuration = Duration.zero,
    this.chunkOverlap = Duration.zero,
    this.vadConfig,
  });

  const AsrTranscriptionPlan.streaming({this.audioDuration = Duration.zero})
    : strategy = AsrTranscriptionStrategy.streaming,
      chunkDuration = Duration.zero,
      chunkOverlap = Duration.zero,
      vadConfig = null;

  bool get supportsInteractiveProgress => strategy.supportsInteractiveProgress;

  bool get supportsCancellation => strategy.supportsCancellation;

  bool get usesVad =>
      strategy == AsrTranscriptionStrategy.chunkedVad && vadConfig != null;

  @override
  List<Object?> get props => [
    strategy,
    audioDuration,
    chunkDuration,
    chunkOverlap,
    vadConfig,
  ];
}
