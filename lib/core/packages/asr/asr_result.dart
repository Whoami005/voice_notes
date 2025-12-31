import 'package:equatable/equatable.dart';

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

  /// Время обработки
  final Duration processingTime;

  /// Является ли результат промежуточным (partial)
  final bool isPartial;

  const AsrResult({
    required this.text,
    this.tokens = const [],
    this.timestamps = const [],
    this.detectedLanguage,
    this.processingTime = Duration.zero,
    this.isPartial = false,
  });

  /// Пустой результат
  static const empty = AsrResult(text: '');

  /// Копия с изменёнными полями
  AsrResult copyWith({
    String? text,
    List<String>? tokens,
    List<double>? timestamps,
    String? detectedLanguage,
    Duration? processingTime,
    bool? isPartial,
  }) {
    return AsrResult(
      text: text ?? this.text,
      tokens: tokens ?? this.tokens,
      timestamps: timestamps ?? this.timestamps,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      processingTime: processingTime ?? this.processingTime,
      isPartial: isPartial ?? this.isPartial,
    );
  }

  @override
  List<Object?> get props => [
    text,
    tokens,
    timestamps,
    detectedLanguage,
    processingTime,
    isPartial,
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
