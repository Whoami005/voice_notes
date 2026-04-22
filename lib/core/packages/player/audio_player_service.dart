/// Статус воспроизведения плеера.
enum PlaybackStatus {
  /// Начальное состояние — источник не загружен.
  init,

  /// Загрузка источника.
  loading,

  /// Источник загружен, готов к воспроизведению.
  ready,

  /// Воспроизводится.
  playing,

  /// На паузе.
  paused,

  /// Дошло до конца.
  completed,

  /// Ошибка загрузки / воспроизведения.
  error;

  bool get isInitial => this == init;

  bool get isLoading => this == loading;

  bool get isReady => this == ready;

  bool get isPlaying => this == playing;

  bool get isPaused => this == paused;

  bool get isCompleted => this == completed;

  bool get isError => this == error;
}

/// Сервис воспроизведения локальных аудиофайлов.
///
/// Тонкая обёртка над конкретной реализацией (`just_audio`).
///
/// ## Lifecycle (важно)
///
/// Одним экземпляром сервиса владеет [AudioPlaybackController].
/// Экранные cubit'ы работают только с controller и не должны вручную
/// управлять lifecycle нативного плеера.
abstract interface class AudioPlayerService {
  /// Поток статуса.
  Stream<PlaybackStatus> get statusStream;

  /// Поток позиции воспроизведения.
  Stream<Duration> get positionStream;

  /// Поток длительности источника (приходит один раз после загрузки).
  Stream<Duration?> get durationStream;

  /// Текущий статус.
  PlaybackStatus get status;

  /// Текущая позиция.
  Duration get position;

  /// Длительность текущего источника (null если не загружен).
  Duration? get duration;

  /// Текущая скорость (1.0 = нормальная).
  double get speed;

  /// Загрузить локальный файл по абсолютному пути.
  ///
  /// Не начинает воспроизведение — вызывай [play] отдельно.
  /// Возвращает длительность, если она известна после загрузки.
  Future<Duration?> load(
    String absolutePath, {
    Duration initialPosition = Duration.zero,
  });

  /// Воспроизведение с текущей позиции.
  Future<void> play();

  /// Пауза.
  Future<void> pause();

  /// Переместиться на указанную позицию.
  Future<void> seek(Duration position);

  /// Изменить скорость (0.5 — 2.0).
  Future<void> setSpeed(double speed);

  /// Остановить воспроизведение и освободить нативные playback-ресурсы.
  Future<void> stop();

  /// Освобождение ресурсов.
  Future<void> dispose();
}
