import 'package:voice_notes/core/packages/downloader/download_manager.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Репозиторий для управления ASR моделями
abstract interface class ModelRepository {
  /// Получить список всех доступных моделей с актуальным статусом скачивания
  Future<List<AsrModelEntity>> getModelsWithStatus();

  /// Скачать модель
  ///
  /// Выполняет полный цикл:
  /// 1. Скачивание архива
  /// 2. Распаковка tar.bz2
  /// 3. Сохранение метаданных в БД
  /// 4. Удаление архива
  Future<void> downloadModel(AsrModelEntity model);

  /// Стрим прогресса скачивания для конкретной модели
  Stream<ModelDownloadProgress> watchDownloadProgress(String modelId);

  /// Стрим прогресса всех скачиваний
  Stream<ModelDownloadProgress> watchAllDownloads();

  /// Отменить скачивание
  Future<void> cancelDownload(String modelId);

  /// Приостановить скачивание
  Future<void> pauseDownload(String modelId);

  /// Возобновить скачивание
  Future<void> resumeDownload(String modelId);

  /// Удалить скачанную модель с устройства
  Future<void> deleteModel(String modelId);

  /// Выбрать модель как активную
  Future<void> selectModel(String modelId);

  /// Получить выбранную (активную) модель
  Future<AsrModelEntity?> getSelectedModel();

  /// Проверить все модели на диске и синхронизировать с БД
  ///
  /// Если файлы модели удалены вне приложения - удаляет запись из БД
  Future<void> verifyAllModels();

  /// Проверить, скачана ли модель
  Future<bool> isModelDownloaded(String modelId);

  /// Получить путь к директории модели (если скачана)
  Future<String?> getModelPath(String modelId);

  /// Освободить ресурсы
  Future<void> dispose();
}
