part of 'recording_cubit.dart';

/// Состояние сессии записи
///
/// Представляет полный жизненный цикл записи:
/// idle -> recording -> transcribing -> success/error -> idle
sealed class RecordingState extends Equatable {
  const RecordingState();
}

/// Idle состояние — готов к записи
final class RecordingIdleState extends RecordingState {
  const RecordingIdleState();

  @override
  List<Object?> get props => [];
}

/// Запись в процессе
final class RecordingActiveState extends RecordingState {
  /// Текущая длительность записи
  final Duration duration;

  /// Амплитуда для визуализации (для будущей анимации waveform)
  final double? amplitude;

  const RecordingActiveState({this.duration = Duration.zero, this.amplitude});

  @override
  List<Object?> get props => [duration, amplitude];

  RecordingActiveState copyWith({Duration? duration, double? amplitude}) {
    return RecordingActiveState(
      duration: duration ?? this.duration,
      amplitude: amplitude ?? this.amplitude,
    );
  }
}

/// Транскрибирование записанного аудио
final class RecordingTranscribingState extends RecordingState {
  /// Промежуточный результат транскрибации (для streaming в будущем)
  final String? partialText;

  /// Путь к аудио файлу
  final String filePath;

  /// Длительность записи
  final Duration duration;

  const RecordingTranscribingState({
    required this.filePath,
    required this.duration,
    this.partialText,
  });

  @override
  List<Object?> get props => [filePath, duration, partialText];
}

/// Транскрибация завершена успешно
final class RecordingSuccessState extends RecordingState {
  /// Распознанный текст
  final String text;

  /// Длительность записи
  final Duration duration;

  /// Путь к аудио файлу (для сохранения с заметкой в будущем)
  final String? audioFilePath;

  /// Определённый язык
  final String? language;

  /// Количество слов
  final int wordCount;

  const RecordingSuccessState({
    required this.text,
    required this.duration,
    required this.wordCount,
    this.audioFilePath,
    this.language,
  });

  @override
  List<Object?> get props => [
    text,
    duration,
    audioFilePath,
    language,
    wordCount,
  ];
}

/// Ошибка во время записи или транскрибации
final class RecordingErrorState extends RecordingState {
  final AppFailure failure;

  const RecordingErrorState(this.failure);

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}

/// Extension для удобной проверки состояния
extension RecordingStateX on RecordingState {
  bool get isIdle => this is RecordingIdleState;

  bool get isRecording => this is RecordingActiveState;

  bool get isTranscribing => this is RecordingTranscribingState;

  bool get isSuccess => this is RecordingSuccessState;

  bool get isError => this is RecordingErrorState;

  /// Конвертация в UI состояние для RecordingInput виджета
  RecordingInputState get uiState => switch (this) {
    RecordingIdleState() => RecordingInputState.idle,
    RecordingActiveState() => RecordingInputState.recording,
    RecordingTranscribingState() => RecordingInputState.transcribing,
    RecordingSuccessState() => RecordingInputState.idle,
    RecordingErrorState() => RecordingInputState.idle,
  };

  /// Получить длительность если доступна
  Duration? get durationOrNull => switch (this) {
    RecordingActiveState(:final duration) => duration,
    RecordingTranscribingState(:final duration) => duration,
    RecordingSuccessState(:final duration) => duration,
    _ => null,
  };
}
