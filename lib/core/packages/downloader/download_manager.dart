import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/core/packages/path/asr_model_paths.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Прогресс скачивания модели
class ModelDownloadProgress extends Equatable {
  final String modelId;
  final DownloadStatus status;
  final double progress;
  final String? errorMessage;
  final bool canResume;

  const ModelDownloadProgress({
    required this.modelId,
    required this.status,
    this.progress = 0.0,
    this.errorMessage,
    this.canResume = false,
  });

  ModelDownloadProgress copyWith({
    String? modelId,
    DownloadStatus? status,
    double? progress,
    String? errorMessage,
    bool? canResume,
  }) {
    return ModelDownloadProgress(
      modelId: modelId ?? this.modelId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      canResume: canResume ?? this.canResume,
    );
  }

  @override
  List<Object?> get props => [
    modelId,
    status,
    progress,
    errorMessage,
    canResume,
  ];
}

/// Менеджер скачивания моделей
///
/// Отвечает за:
/// - Скачивание моделей в фоне
/// - Отслеживание прогресса
/// - Pause/Resume/Cancel
/// - Уведомления в системной шторке
@singleton
class DownloadManager {
  static const String _downloadGroup = 'asr_models';
  static const int _maxConcurrent = 2;

  final _progressController =
      StreamController<ModelDownloadProgress>.broadcast();

  final Map<String, String> _modelIdToTaskId = {};
  final Map<String, String> _taskIdToModelId = {};

  bool _initialized = false;

  /// Стрим прогресса для всех загрузок
  Stream<ModelDownloadProgress> get progressStream =>
      _progressController.stream;

  /// Инициализация менеджера загрузок
  @PostConstruct(preResolve: true)
  Future<void> init() async {
    if (_initialized) return;

    // Настраиваем очередь
    await FileDownloader().configure(
      globalConfig: [(Config.holdingQueue, (_downloadGroup, _maxConcurrent))],
    );

    // Настраиваем уведомления
    FileDownloader().configureNotification(
      running: const TaskNotification('Скачивание модели', '{filename}'),
      complete: const TaskNotification('Модель скачана', '{filename}'),
      error: const TaskNotification('Ошибка скачивания', '{filename}'),
      paused: const TaskNotification('Скачивание приостановлено', '{filename}'),
      progressBar: true,
    );

    // Подписываемся на обновления
    FileDownloader().updates.listen(_handleUpdate);

    // Запускаем FileDownloader
    await FileDownloader().start(autoCleanDatabase: true);

    _initialized = true;
  }

  /// Добавить модель в очередь скачивания
  ///
  /// Возвращает taskId для отслеживания
  Future<String> enqueue(AsrModelEntity model) async {
    if (!_initialized) {
      throw StateError('DownloadManager not initialized. Call init() first.');
    }

    final modelId = model.uuid.value;

    // Проверяем, не скачивается ли уже
    if (_modelIdToTaskId.containsKey(modelId)) {
      return _modelIdToTaskId[modelId]!;
    }

    final task = DownloadTask(
      url: model.downloadUrl,
      filename: '${model.modelDirName}.tar.bz2',
      directory: AsrModelPaths.downloadsSubdir,
      group: _downloadGroup,
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
      metaData: modelId,
    );

    _modelIdToTaskId[modelId] = task.taskId;
    _taskIdToModelId[task.taskId] = modelId;

    // Отправляем начальный статус
    _progressController.add(
      ModelDownloadProgress(modelId: modelId, status: DownloadStatus.queued),
    );

    final success = await FileDownloader().enqueue(task);
    if (!success) {
      _modelIdToTaskId.remove(modelId);
      _taskIdToModelId.remove(task.taskId);

      _progressController.add(
        ModelDownloadProgress(
          modelId: modelId,
          status: DownloadStatus.failed,
          errorMessage: 'Не удалось добавить в очередь',
        ),
      );
    }

    return task.taskId;
  }

  /// Приостановить скачивание
  Future<void> pause(String modelId) async {
    final taskId = _modelIdToTaskId[modelId];
    if (taskId == null) return;

    final task = await FileDownloader().taskForId(taskId);
    if (task is DownloadTask) await FileDownloader().pause(task);
  }

  /// Возобновить скачивание
  Future<void> resume(String modelId) async {
    final taskId = _modelIdToTaskId[modelId];
    if (taskId == null) return;

    final task = await FileDownloader().taskForId(taskId);
    if (task is DownloadTask) await FileDownloader().resume(task);
  }

  /// Отменить скачивание
  Future<void> cancel(String modelId) async {
    final taskId = _modelIdToTaskId[modelId];
    if (taskId == null) return;

    await FileDownloader().cancelTaskWithId(taskId);

    _modelIdToTaskId.remove(modelId);
    _taskIdToModelId.remove(taskId);

    _progressController.add(
      ModelDownloadProgress(modelId: modelId, status: DownloadStatus.cancelled),
    );
  }

  /// Проверить, можно ли возобновить скачивание
  Future<bool> canResume(String modelId) async {
    final taskId = _modelIdToTaskId[modelId];
    if (taskId == null) return false;

    final task = await FileDownloader().taskForId(taskId);
    if (task == null) return false;

    return FileDownloader().taskCanResume(task);
  }

  /// Получить путь к скачанному архиву
  ///
  /// Возвращает фактический путь к файлу если загрузка завершена успешно.
  Future<String?> getDownloadedArchivePath(String modelId) async {
    final taskId = _modelIdToTaskId[modelId];
    if (taskId == null) return null;

    final record = await FileDownloader().database.recordForId(taskId);
    if (record == null || record.status != TaskStatus.complete) {
      return null;
    }

    // Используем API библиотеки для получения фактического пути
    return record.task.filePath();
  }

  /// Очистить завершенную задачу из трекинга
  void clearTask(String modelId) {
    final taskId = _modelIdToTaskId.remove(modelId);

    if (taskId != null) _taskIdToModelId.remove(taskId);
  }

  void _handleUpdate(TaskUpdate update) {
    final modelId = _taskIdToModelId[update.task.taskId];
    if (modelId == null) return;

    switch (update) {
      case TaskStatusUpdate():
        _handleStatusUpdate(modelId, update);
      case TaskProgressUpdate():
        _handleProgressUpdate(modelId, update);
    }
  }

  void _handleStatusUpdate(String modelId, TaskStatusUpdate update) {
    final status = switch (update.status) {
      TaskStatus.enqueued => DownloadStatus.queued,
      TaskStatus.running => DownloadStatus.downloading,
      TaskStatus.complete => DownloadStatus.completed,
      TaskStatus.failed => DownloadStatus.failed,
      TaskStatus.canceled => DownloadStatus.cancelled,
      TaskStatus.paused => DownloadStatus.paused,
      TaskStatus.notFound => DownloadStatus.failed,
      TaskStatus.waitingToRetry => DownloadStatus.downloading,
    };

    String? errorMessage;
    if (update.status == TaskStatus.failed && update.exception != null) {
      errorMessage = update.exception.toString();
    }

    _progressController.add(
      ModelDownloadProgress(
        modelId: modelId,
        status: status,
        errorMessage: errorMessage,
      ),
    );

    // Очищаем маппинг при завершении/отмене/ошибке
    if (status == DownloadStatus.completed ||
        status == DownloadStatus.cancelled ||
        status == DownloadStatus.failed) {
      // Не очищаем сразу для completed, т.к. нужен путь к файлу
      if (status != DownloadStatus.completed) {
        clearTask(modelId);
      }
    }
  }

  void _handleProgressUpdate(String modelId, TaskProgressUpdate update) {
    _progressController.add(
      ModelDownloadProgress(
        modelId: modelId,
        status: DownloadStatus.downloading,
        progress: update.progress,
      ),
    );
  }

  /// Освободить ресурсы
  @disposeMethod
  Future<void> dispose() async {
    await FileDownloader().resetUpdates();
    await _progressController.close();
  }
}
