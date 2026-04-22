import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// RTF (Real-Time Factor) = время_обработки / длительность_аудио.
/// Консервативные оценки для UI-ETA, не реальный прогресс. Источник цифр —
/// `docs/sherpa_onnx_reference.md`.
abstract final class AsrRtfEstimates {
  static const double _whisperTinyEn = 0.12;
  static const double _whisperSmall = 0.18;
  static const double _whisperMedium = 0.28;
  static const double _transducerDefault = 0.12;
  static const double _unknown = 0.16;

  static double forModel({AsrModelIdEnum? modelId, AsrModelType? modelType}) {
    if (modelId != null) {
      return switch (modelId) {
        AsrModelIdEnum.whisperTinyEn => _whisperTinyEn,
        AsrModelIdEnum.whisperSmall => _whisperSmall,
        AsrModelIdEnum.whisperMedium => _whisperMedium,
        AsrModelIdEnum.parakeetTdtV3 ||
        AsrModelIdEnum.streamingZipformerEn ||
        AsrModelIdEnum.streamingZipformerEn20M => _transducerDefault,
      };
    }

    return switch (modelType) {
      AsrModelType.whisper => _unknown,
      AsrModelType.streamingTransducer ||
      AsrModelType.offlineTransducer => _transducerDefault,
      null => _unknown,
    };
  }

  /// Минимум 1 секунда, чтобы UI не показывал «~0 сек».
  static Duration estimate(
    Duration audio, {
    AsrModelIdEnum? modelId,
    AsrModelType? modelType,
  }) {
    final rtf = forModel(modelId: modelId, modelType: modelType);
    final millis = (audio.inMilliseconds * rtf).round();
    final clamped = millis < 1000 ? 1000 : millis;

    return Duration(milliseconds: clamped);
  }
}
