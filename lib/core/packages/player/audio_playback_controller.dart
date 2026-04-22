import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────

/// Состояние трека для UI.
class TrackState extends Equatable {
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;

  const TrackState({
    this.status = PlaybackStatus.init,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  const TrackState.initial() : this();

  @override
  List<Object?> get props => [status, position, duration];
}

/// Глобальная playback-сессия для root-level UI.
class PlaybackSessionState extends Equatable {
  final String? trackId;
  final String? title;
  final String? folderId;
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final double speed;

  const PlaybackSessionState({
    this.trackId,
    this.title,
    this.folderId,
    this.status = PlaybackStatus.init,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
  });

  const PlaybackSessionState.hidden({this.speed = 1.0})
    : trackId = null,
      title = null,
      folderId = null,
      status = PlaybackStatus.init,
      position = Duration.zero,
      duration = Duration.zero;

  bool get isVisible => trackId != null && status.isPlaying;

  @override
  List<Object?> get props => [
    trackId,
    title,
    folderId,
    status,
    position,
    duration,
    speed,
  ];
}

/// Кешированное состояние неактивного трека.
class CachedTrackState {
  String absolutePath;
  String title;
  String? folderId;
  Duration position;
  Duration duration;
  PlaybackStatus status;

  CachedTrackState({
    required this.absolutePath,
    this.title = '',
    this.folderId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.status = PlaybackStatus.init,
  });
}

// ─────────────────────────────────────────────────────────────
// Contract
// ─────────────────────────────────────────────────────────────

/// Координатор воспроизведения аудио между экранами.
///
/// Владеет одним нативным плеером. При переключении треков сохраняет
/// позицию текущего в кеш и загружает новый. Синглтон на весь lifecycle.
abstract interface class AudioPlaybackController {
  /// Регистрирует трек с начальным кешированным состоянием.
  /// Если уже зарегистрирован — обновляет path/metadata и сохраняет progress.
  /// Позволяет UI сразу показать duration/position без загрузки в плеер.
  void register(String trackId, CachedTrackState state);

  /// Начать/возобновить воспроизведение.
  /// Авто-пауза текущего трека с кешированием позиции.
  Future<void> play(String trackId);

  /// Пауза текущего трека.
  Future<void> pause();

  /// Toggle play/pause для конкретного трека.
  Future<void> togglePlayPause(String trackId);

  /// Перемотка. Не меняет play/pause статус.
  /// active трек → seek в плеере.
  /// cached трек → обновить позицию в кеше.
  Future<void> seek(String trackId, Duration position);

  /// Скорость воспроизведения. Глобальная.
  Future<void> setSpeed(double speed);

  /// Стрим состояния конкретного трека.
  Stream<TrackState> trackStateStream(String trackId);

  /// Текущая глобальная playback-сессия.
  PlaybackSessionState get session;

  /// Поток изменений playback-сессии.
  Stream<PlaybackSessionState> get sessionStream;

  /// Явно завершает текущую playback-сессию и выгружает активный трек.
  Future<void> clearSession();

  /// Парсит аудио файл и возвращает нормализованные амплитуды (0.0–1.0).
  /// Кеширует результат. Возвращает null если парсинг не удался.
  /// trackId должен быть зарегистрирован через register().
  Future<List<double>?> getWaveform(String trackId);

  /// Dispose плеера. Только при закрытии приложения.
  Future<void> dispose();
}
