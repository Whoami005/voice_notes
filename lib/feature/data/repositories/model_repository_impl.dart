import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/archive/archive_extractor.dart';
import 'package:voice_notes/core/packages/downloader/download_manager.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/core/packages/path/asr_model_paths.dart';
import 'package:voice_notes/feature/data/local/data_sources/model_local_data_source.dart';
import 'package:voice_notes/feature/data/local/models/downloaded_model_object.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';

/// Реализация репозитория для управления ASR моделями
@Singleton(as: ModelRepository)
class ModelRepositoryImpl implements ModelRepository {
  final ModelLocalDataSource _localDataSource;
  final DownloadManager _downloadManager;

  /// Контроллер для стрима прогресса распаковки
  final _extractionController =
      StreamController<ModelDownloadProgress>.broadcast();

  ModelRepositoryImpl(this._localDataSource, this._downloadManager);

  @override
  Future<List<AsrModelEntity>> getModelsWithStatus() async {
    final downloadedModels = await _localDataSource.getAll();
    final downloadedMap = {
      for (final model in downloadedModels) model.modelId: model,
    };

    final result = <AsrModelEntity>[];

    for (final model in AsrModelEntity.availableModels) {
      final downloaded = downloadedMap[model.uuid];
      result.add(
        model.copyWith(
          isDownloaded: downloaded != null,
          isSelected: downloaded?.isSelected ?? false,
        ),
      );
    }

    return result;
  }

  @override
  Future<void> downloadModel(AsrModelEntity model) async {
    // Подписываемся на завершение скачивания
    late StreamSubscription<ModelDownloadProgress> subscription;

    subscription = _downloadManager.progressStream
        .where((progress) => progress.modelId == model.uuid)
        .listen((progress) async {
          if (progress.status == DownloadStatus.completed) {
            await subscription.cancel();
            await _handleDownloadComplete(model);
          }
        });

    // Добавляем в очередь скачивания
    await _downloadManager.enqueue(model);
  }

  /// Обработка завершения скачивания
  Future<void> _handleDownloadComplete(AsrModelEntity model) async {
    // Получаем путь к скачанному архиву
    final archivePath = await _downloadManager.getDownloadedArchivePath(
      model.uuid,
    );

    if (archivePath == null) {
      _extractionController.add(
        ModelDownloadProgress(
          modelId: model.uuid,
          status: DownloadStatus.failed,
          errorMessage: 'Ошибка распаковки: путь до архива не найден',
        ),
      );

      return;
    }

    // Отправляем статус "распаковка"
    _extractionController.add(
      ModelDownloadProgress(
        modelId: model.uuid,
        status: DownloadStatus.extracting,
      ),
    );

    try {
      // Получаем путь для распаковки
      final modelsDir = await AsrModelPaths.modelsDir;
      final modelPath = await AsrModelPaths.modelPath(model.modelDirName);

      // Распаковываем архив
      await ArchiveExtractor.extractTarBz2(
        archivePath: archivePath,
        destinationDir: modelsDir,
      );

      // Вычисляем размер распакованной модели
      final modelDirectory = Directory(modelPath);
      int totalSize = 0;

      if (modelDirectory.existsSync()) {
        await for (final entity in modelDirectory.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      // Сохраняем метаданные в БД
      final downloadedModel = DownloadedModelObject(
        modelId: model.uuid,
        modelDirName: model.modelDirName,
        localPath: AsrModelPaths.modelRelativePath(model.modelDirName),
        downloadedAt: DateTime.now(),
        fileSizeBytes: totalSize,
      );
      await _localDataSource.save(downloadedModel);

      // Очищаем задачу из менеджера загрузок
      _downloadManager.clearTask(model.uuid);

      // Отправляем статус "готово"
      _extractionController.add(
        ModelDownloadProgress(
          modelId: model.uuid,
          status: DownloadStatus.completed,
        ),
      );
    } catch (e, s) {
      AppFailure.from(e, s);

      // Отправляем статус "ошибка"
      _extractionController.add(
        ModelDownloadProgress(
          modelId: model.uuid,
          status: DownloadStatus.failed,
          errorMessage: 'Ошибка распаковки: $e',
        ),
      );
    }
  }

  @override
  Stream<ModelDownloadProgress> watchDownloadProgress(String modelId) {
    return watchAllDownloads().where((progress) => progress.modelId == modelId);
  }

  @override
  Stream<ModelDownloadProgress> watchAllDownloads() {
    // Объединяем стримы из DownloadManager и extraction
    return _downloadManager.progressStream.mergeWith([
      _extractionController.stream,
    ]);
  }

  @override
  Future<void> cancelDownload(String modelId) async {
    await _downloadManager.cancel(modelId);
  }

  @override
  Future<void> pauseDownload(String modelId) async {
    await _downloadManager.pause(modelId);
  }

  @override
  Future<void> resumeDownload(String modelId) async {
    await _downloadManager.resume(modelId);
  }

  @override
  Future<void> deleteModel(String modelId) async {
    // Получаем информацию о модели
    final model = await _localDataSource.getByModelId(modelId);
    if (model == null) return;

    // Удаляем файлы с диска
    final fullPath = await AsrModelPaths.resolveRelativePath(model.localPath);
    final directory = Directory(fullPath);
    if (directory.existsSync()) await directory.delete(recursive: true);

    // Удаляем запись из БД
    await _localDataSource.delete(modelId);
  }

  @override
  Future<void> selectModel(String modelId) async {
    await _localDataSource.setSelected(modelId);
  }

  @override
  Future<AsrModelEntity?> getSelectedModel() async {
    final selected = await _localDataSource.getSelected();
    if (selected == null) return null;

    // Находим соответствующую модель из списка доступных
    for (final model in AsrModelEntity.availableModels) {
      if (model.uuid == selected.modelId) {
        return model.copyWith(isDownloaded: true, isSelected: true);
      }
    }
    return null;
  }

  @override
  Future<void> verifyAllModels() async {
    final downloadedModels = await _localDataSource.getAll();

    for (final model in downloadedModels) {
      final exists = await _localDataSource.verifyModelFiles(model.modelId);
      if (!exists) {
        // Файлы удалены вне приложения - удаляем запись из БД
        await _localDataSource.delete(model.modelId);
      }
    }
  }

  @override
  Future<bool> isModelDownloaded(String modelId) async {
    final model = await _localDataSource.getByModelId(modelId);
    if (model == null) return false;

    // Дополнительно проверяем наличие файлов
    return _localDataSource.verifyModelFiles(modelId);
  }

  @override
  Future<String?> getModelPath(String modelId) async {
    final model = await _localDataSource.getByModelId(modelId);
    if (model == null) return null;

    // Проверяем наличие файлов
    final exists = await _localDataSource.verifyModelFiles(modelId);
    if (!exists) {
      // Файлы удалены - очищаем БД
      await _localDataSource.delete(modelId);
      return null;
    }

    return AsrModelPaths.resolveRelativePath(model.localPath);
  }

  /// Освободить ресурсы
  @override
  @disposeMethod
  Future<void> dispose() async {
    await _extractionController.close();
  }
}

/// Extension для объединения стримов
extension StreamMerge<T> on Stream<T> {
  Stream<T> mergeWith(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>.broadcast();

    final subscriptions = <StreamSubscription<T>>[];

    void addSubscription(Stream<T> stream) {
      final sub = stream.listen(controller.add, onError: controller.addError);
      subscriptions.add(sub);
    }

    addSubscription(this);
    streams.forEach(addSubscription);

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }
}
