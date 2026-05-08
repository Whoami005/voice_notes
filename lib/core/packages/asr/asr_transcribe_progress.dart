// ignore_for_file: comment_references

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';

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

  /// Какая стратегия исполнения сейчас активна.
  final AsrTranscriptionStrategy strategy;

  /// Текущий этап пайплайна.
  final AsrTranscribeStage stage;

  /// Сколько decode/VAD-units уже завершено.
  final int processedUnits;

  /// Общее число decode/VAD-units.
  final int totalUnits;

  const AsrTranscribeProgress({
    required this.progress,
    required this.partialText,
    required this.processedAudio,
    required this.totalAudio,
    this.strategy = AsrTranscriptionStrategy.streaming,
    this.stage = AsrTranscribeStage.decoding,
    this.processedUnits = 0,
    this.totalUnits = 0,
  });

  /// Прогресс в целых процентах для отображения в UI.
  int get percent => (progress * 100).floor();

  @override
  List<Object?> get props => [
    progress,
    partialText,
    processedAudio,
    totalAudio,
    strategy,
    stage,
    processedUnits,
    totalUnits,
  ];
}
