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
  Stream<ModelDownloadProgress> watchDownloadProgress(String uid);

  /// Стрим прогресса всех скачиваний
  Stream<ModelDownloadProgress> watchAllDownloads();

  /// Отменить скачивание
  Future<void> cancelDownload(String uid);

  /// Приостановить скачивание
  Future<void> pauseDownload(String uid);

  /// Возобновить скачивание
  Future<void> resumeDownload(String uid);

  /// Удалить скачанную модель с устройства
  Future<void> deleteModel(String uid);

  /// Выбрать модель как активную
  Future<void> selectModel(String uid);

  /// Получить выбранную (активную) модель
  Future<AsrModelEntity?> getSelectedModel();

  /// Стрим всех моделей с актуальным статусом
  Stream<List<AsrModelEntity>> watchModelsWithStatus();

  /// Стрим выбранной модели с реактивными обновлениями
  Stream<AsrModelEntity?> watchSelectedModel();

  /// Проверить все модели на диске и синхронизировать с БД
  ///
  /// Если файлы модели удалены вне приложения - удаляет запись из БД
  Future<void> verifyAllModels();

  /// Проверить, скачана ли модель
  Future<bool> isModelDownloaded(String uid);

  /// Получить путь к директории модели (если скачана)
  Future<String?> getModelPath(String uid);

  /// Освободить ресурсы
  Future<void> dispose();
}
