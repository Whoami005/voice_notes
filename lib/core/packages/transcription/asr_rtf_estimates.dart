import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// RTF (Real-Time Factor) = время_обработки / длительность_аудио.
/// Консервативные оценки для UI-ETA, не реальный прогресс. Источник цифр —
/// `docs/sherpa_onnx_reference.md`.
abstract final class AsrRtfEstimates {
  static const double _whisperDefault = 0.15;
  static const double _transducerDefault = 0.12;
  static const double _unknown = 0.15;

  static double forModel(AsrModelType? modelType) {
    return switch (modelType) {
      AsrModelType.whisper => _whisperDefault,
      AsrModelType.streamingTransducer ||
      AsrModelType.offlineTransducer => _transducerDefault,
      null => _unknown,
    };
  }

  /// Минимум 1 секунда, чтобы UI не показывал «~0 сек».
  static Duration estimate(Duration audio, AsrModelType? modelType) {
    final rtf = forModel(modelType);
    final millis = (audio.inMilliseconds * rtf).round();
    final clamped = millis < 1000 ? 1000 : millis;

    return Duration(milliseconds: clamped);
  }
}
