/// Статус скачивания модели
enum DownloadStatus {
  /// Модель не скачана
  idle,

  /// Выполняются проверки перед скачиванием
  preparing,

  /// В очереди на скачивание
  queued,

  /// Скачивается (progress 0.0-1.0)
  downloading,

  /// Распаковывается
  extracting,

  /// Готова к использованию
  completed,

  /// Ошибка при скачивании
  failed,

  /// Отменена пользователем
  cancelled,

  /// Приостановлена
  paused;

  bool get isIdle => this == idle;

  bool get isPreparing => this == preparing;

  bool get isQueued => this == queued;

  bool get isDownloading => this == downloading;

  bool get isExtracting => this == extracting;

  bool get isCompleted => this == completed;

  bool get isFailed => this == failed;

  bool get isCancelled => this == cancelled;

  bool get isPaused => this == paused;
}
