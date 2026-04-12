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
/// Тонкая обёртка над конкретной реализацией (just_audio). Абстракция
/// существует чтобы:
/// - мокировать в тестах без зависимости от платформы;
/// - инкапсулировать маппинг состояний конкретного пакета в общий enum.
///
/// ## Lifecycle (важно)
///
/// Сервис зарегистрирован в DI как **factory** (`@Injectable`), а НЕ
/// singleton — каждый `getIt<AudioPlayerService>()` создаёт новый instance,
/// чтобы разные экраны не делили один плеер.
///
/// **Контракт:** потребитель ОБЯЗАН вызвать [dispose] при завершении —
/// обычно из `close()` своего cubit'а или `dispose()` своего `State`.
/// Без этого нативный плеер утечёт и может заморозить аудио на устройстве.
///
/// Эталонный пример: `NotePlaybackCubit.close()`.
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
  /// Не начинает воспроизведение — вызывай [play] отдельно.
  Future<void> load(String absolutePath);

  /// Воспроизведение с текущей позиции.
  Future<void> play();

  /// Пауза.
  Future<void> pause();

  /// Переместиться на указанную позицию.
  Future<void> seek(Duration position);

  /// Изменить скорость (0.5 — 2.0).
  Future<void> setSpeed(double speed);

  /// Остановить и очистить источник.
  Future<void> stop();

  /// Освобождение ресурсов.
  Future<void> dispose();
}
