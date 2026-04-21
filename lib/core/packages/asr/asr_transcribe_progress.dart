import 'package:equatable/equatable.dart';

/// Прогресс транскрибации для streaming-совместимых моделей.
///
/// Эмитится через `onProgress` callback в [AsrService.transcribeFile] по мере
/// обработки чанков аудио. Для non-streaming моделей (Whisper) не приходит.
class AsrTranscribeProgress extends Equatable {
  /// Доля обработанного аудио, `0.0..1.0`.
  final double progress;

  /// Накопленный partial text на момент события.
  final String partialText;

  /// Сколько аудио уже обработано.
  final Duration processedAudio;

  /// Полная длительность аудио.
  final Duration totalAudio;

  const AsrTranscribeProgress({
    required this.progress,
    required this.partialText,
    required this.processedAudio,
    required this.totalAudio,
  });

  /// Прогресс в целых процентах для отображения в UI.
  int get percent => (progress * 100).floor();

  @override
  List<Object?> get props => [
    progress,
    partialText,
    processedAudio,
    totalAudio,
  ];
}
