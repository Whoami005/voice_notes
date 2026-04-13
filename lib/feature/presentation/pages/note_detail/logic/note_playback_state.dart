part of 'note_playback_cubit.dart';

class NotePlaybackState extends StatusState {
  /// Текущий статус плеера (идеал/загрузка/играет/пауза/конец/ошибка).
  final PlaybackStatus playbackStatus;

  /// Текущая позиция воспроизведения.
  final Duration position;

  /// Длительность источника.
  final Duration duration;

  /// Скорость воспроизведения.
  final double speed;

  const NotePlaybackState({
    super.status,
    super.failure,
    this.playbackStatus = PlaybackStatus.init,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
  });

  /// Идёт ли сейчас воспроизведение.
  bool get isPlaying => playbackStatus.isPlaying;

  /// Загружается ли источник.
  bool get isBuffering => playbackStatus.isLoading;

  @override
  NotePlaybackState copyWith({
    Status? status,
    AppFailure? failure,
    PlaybackStatus? playbackStatus,
    Duration? position,
    Duration? duration,
    double? speed,
  }) {
    return NotePlaybackState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      playbackStatus: playbackStatus ?? this.playbackStatus,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    playbackStatus,
    position,
    duration,
    speed,
  ];
}
