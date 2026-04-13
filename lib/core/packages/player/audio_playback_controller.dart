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

/// Кешированное состояние неактивного трека.
class CachedTrackState {
  final String absolutePath;
  Duration position;
  Duration duration;
  PlaybackStatus status;

  CachedTrackState({
    required this.absolutePath,
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
  /// Если уже зарегистрирован — no-op.
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

  /// Stop + очистка кеша + закрытие subjects. Плеер НЕ dispose.
  Future<void> releaseAll();

  /// Стрим состояния конкретного трека.
  Stream<TrackState> trackStateStream(String trackId);

  /// Стрим ID активного трека.
  Stream<String?> get activeTrackIdStream;

  /// Синхронный ID активного трека.
  String? get activeTrackId;

  /// Текущая скорость.
  double get speed;

  /// Парсит аудио файл и возвращает нормализованные амплитуды (0.0–1.0).
  /// Кеширует результат. Возвращает null если парсинг не удался.
  /// trackId должен быть зарегистрирован через register().
  Future<List<double>?> getWaveform(String trackId);

  /// Dispose плеера. Только при закрытии приложения.
  Future<void> dispose();
}
