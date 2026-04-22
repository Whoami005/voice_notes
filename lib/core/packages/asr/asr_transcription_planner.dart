import 'package:voice_notes/core/packages/asr/asr_transcription_plan.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

abstract final class AsrTranscriptionPlanner {
  static AsrTranscriptionPlan resolve({
    required AsrModelEntity model,
    required Duration audioDuration,
    AsrTranscriptionStrategy strategyOverride = AsrTranscriptionStrategy.auto,
    String? vadModelPath,
  }) {
    return switch (model.modelType) {
      AsrModelType.streamingTransducer => AsrTranscriptionPlan.streaming(
        audioDuration: audioDuration,
      ),
      AsrModelType.whisper || AsrModelType.offlineTransducer => _resolveOffline(
        model: model,
        audioDuration: audioDuration,
        strategyOverride: strategyOverride,
        vadModelPath: vadModelPath,
      ),
    };
  }

  static AsrTranscriptionPlan _resolveOffline({
    required AsrModelEntity model,
    required Duration audioDuration,
    required AsrTranscriptionStrategy strategyOverride,
    required String? vadModelPath,
  }) {
    final profile =
        (model.offlineTranscriptionProfile ??
                AsrOfflineTranscriptionProfile.defaultOffline)
            .withVadModelPath(vadModelPath);

    final strategy = _selectOfflineStrategy(
      profile: profile,
      audioDuration: audioDuration,
      strategyOverride: strategyOverride,
    );

    return AsrTranscriptionPlan(
      strategy: strategy,
      audioDuration: audioDuration,
      chunkDuration: profile.chunkDuration,
      chunkOverlap: profile.chunkOverlap,
      vadConfig: strategy == AsrTranscriptionStrategy.chunkedVad
          ? profile.vadConfig
          : null,
    );
  }

  static AsrTranscriptionStrategy _selectOfflineStrategy({
    required AsrOfflineTranscriptionProfile profile,
    required Duration audioDuration,
    required AsrTranscriptionStrategy strategyOverride,
  }) {
    if (!strategyOverride.isAuto) {
      final isVad =
          strategyOverride.isChunkedVad && !profile.vadConfig.isConfigured;
      if (isVad) return AsrTranscriptionStrategy.chunked;

      return strategyOverride;
    }

    if (audioDuration <= Duration.zero) {
      return AsrTranscriptionStrategy.chunked;
    }

    final estimatedProcessingTime = Duration(
      milliseconds: (audioDuration.inMilliseconds * profile.estimatedRtf)
          .round(),
    );

    if (audioDuration <= profile.singlePassMaxAudio &&
        estimatedProcessingTime <= profile.singlePassMaxProcessingTime) {
      return AsrTranscriptionStrategy.singlePass;
    }

    if (audioDuration <= profile.chunkedMaxAudio ||
        !profile.vadConfig.isConfigured) {
      return AsrTranscriptionStrategy.chunked;
    }

    return AsrTranscriptionStrategy.chunkedVad;
  }
}
