import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_segment.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';

class AsrTranscriptionStats extends Equatable {
  final int processedUnits;
  final int totalUnits;
  final bool usedVad;
  final bool fellBackFromVad;

  const AsrTranscriptionStats({
    this.processedUnits = 0,
    this.totalUnits = 0,
    this.usedVad = false,
    this.fellBackFromVad = false,
  });

  @override
  List<Object?> get props => [
    processedUnits,
    totalUnits,
    usedVad,
    fellBackFromVad,
  ];
}

/// Результат распознавания речи
class AsrResult extends Equatable {
  /// Распознанный текст
  final String text;

  /// Токены (слова/части слов)
  final List<String> tokens;

  /// Временные метки для каждого токена (в секундах)
  final List<double> timestamps;

  /// Определённый язык (если поддерживается моделью)
  final String? detectedLanguage;

  /// Определённая эмоция (если поддерживается моделью)
  final String? emotionLabel;

  /// Определённое событие (если поддерживается моделью)
  final String? eventLabel;

  /// Признак, что pipeline использовал ITN.
  final bool? usedItn;

  /// Признак, что pipeline использовал встроенную пунктуацию.
  final bool? usedPunctuation;

  /// Время обработки
  final Duration processingTime;

  /// Является ли результат промежуточным (partial)
  final bool isPartial;

  /// Какая стратегия реально использовалась для decode.
  final AsrTranscriptionStrategy strategyUsed;

  /// Длительность исходного аудио, если была известна пайплайну.
  final Duration audioDuration;

  /// Сегментная метаинформация итоговой транскрибации.
  final List<AsrTranscriptionSegment> segments;

  /// Дополнительная статистика выполнения.
  final AsrTranscriptionStats stats;

  const AsrResult({
    required this.text,
    this.tokens = const [],
    this.timestamps = const [],
    this.detectedLanguage,
    this.emotionLabel,
    this.eventLabel,
    this.usedItn,
    this.usedPunctuation,
    this.processingTime = Duration.zero,
    this.isPartial = false,
    this.strategyUsed = AsrTranscriptionStrategy.singlePass,
    this.audioDuration = Duration.zero,
    this.segments = const [],
    this.stats = const AsrTranscriptionStats(),
  });

  /// Пустой результат
  static const empty = AsrResult(text: '');

  /// Копия с изменёнными полями
  AsrResult copyWith({
    String? text,
    List<String>? tokens,
    List<double>? timestamps,
    String? detectedLanguage,
    String? Function()? emotionLabel,
    String? Function()? eventLabel,
    bool? Function()? usedItn,
    bool? Function()? usedPunctuation,
    Duration? processingTime,
    bool? isPartial,
    AsrTranscriptionStrategy? strategyUsed,
    Duration? audioDuration,
    List<AsrTranscriptionSegment>? segments,
    AsrTranscriptionStats? stats,
  }) {
    return AsrResult(
      text: text ?? this.text,
      tokens: tokens ?? this.tokens,
      timestamps: timestamps ?? this.timestamps,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      emotionLabel: emotionLabel != null ? emotionLabel() : this.emotionLabel,
      eventLabel: eventLabel != null ? eventLabel() : this.eventLabel,
      usedItn: usedItn != null ? usedItn() : this.usedItn,
      usedPunctuation: usedPunctuation != null
          ? usedPunctuation()
          : this.usedPunctuation,
      processingTime: processingTime ?? this.processingTime,
      isPartial: isPartial ?? this.isPartial,
      strategyUsed: strategyUsed ?? this.strategyUsed,
      audioDuration: audioDuration ?? this.audioDuration,
      segments: segments ?? this.segments,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
    text,
    tokens,
    timestamps,
    detectedLanguage,
    emotionLabel,
    eventLabel,
    usedItn,
    usedPunctuation,
    processingTime,
    isPartial,
    strategyUsed,
    audioDuration,
    segments,
    stats,
  ];
}

/// Промежуточный результат streaming распознавания
class AsrStreamingResult extends Equatable {
  /// Промежуточный текст
  final String partialText;

  /// Достигнута ли граница высказывания (endpoint)
  final bool isEndpoint;

  const AsrStreamingResult({
    required this.partialText,
    this.isEndpoint = false,
  });

  @override
  List<Object?> get props => [partialText, isEndpoint];
}
