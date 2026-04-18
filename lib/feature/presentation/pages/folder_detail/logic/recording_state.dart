part of 'recording_cubit.dart';

/// Жизненный цикл записи: idle → recording → transcribing → success/error
/// → idle.
sealed class RecordingState extends Equatable {
  const RecordingState();
}

final class RecordingIdleState extends RecordingState {
  const RecordingIdleState();

  @override
  List<Object?> get props => [];
}

final class RecordingActiveState extends RecordingState {
  final Duration duration;
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

final class RecordingTranscribingState extends RecordingState {
  final String? partialText;
  final String filePath;
  final Duration duration;

  const RecordingTranscribingState({
    required this.filePath,
    required this.duration,
    this.partialText,
  });

  @override
  List<Object?> get props => [filePath, duration, partialText];
}

final class RecordingSuccessState extends RecordingState {
  final String text;
  final Duration duration;
  final String? audioFilePath;
  final String? language;
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

final class RecordingErrorState extends RecordingState {
  final AppFailure failure;

  const RecordingErrorState(this.failure);

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}

extension RecordingStateX on RecordingState {
  bool get isIdle => this is RecordingIdleState;

  bool get isRecording => this is RecordingActiveState;

  bool get isTranscribing => this is RecordingTranscribingState;

  bool get isSuccess => this is RecordingSuccessState;

  bool get isError => this is RecordingErrorState;

  /// `RecordingTranscribingState` используется только Quick Record'ом (там
  /// UI-биндинг через флаг `isTranscribing`). В folder-баре этот state
  /// никогда не эмитится, поэтому маппим его в `idle`.
  RecordingInputState get uiState => switch (this) {
    RecordingIdleState() => RecordingInputState.idle,
    RecordingActiveState() => RecordingInputState.recording,
    RecordingTranscribingState() => RecordingInputState.idle,
    RecordingSuccessState() => RecordingInputState.idle,
    RecordingErrorState() => RecordingInputState.idle,
  };

  Duration? get durationOrNull => switch (this) {
    RecordingActiveState(:final duration) => duration,
    RecordingTranscribingState(:final duration) => duration,
    RecordingSuccessState(:final duration) => duration,
    _ => null,
  };
}
