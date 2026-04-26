import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
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
      final downloaded = downloadedMap[model.uuid.value];
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
    late StreamSubscription<ModelDownloadProgress> subscription;

    subscription = _downloadManager.progressStream
        .where((progress) => progress.modelId == model.uuid.value)
        .listen((progress) {
          unawaited(
            _handleTerminalDownloadProgress(model, progress, subscription),
          );
        });

    try {
      await _downloadManager.enqueue(model);
    } catch (_) {
      await subscription.cancel();
      rethrow;
    }
  }

  Future<void> _handleTerminalDownloadProgress(
    AsrModelEntity model,
    ModelDownloadProgress progress,
    StreamSubscription<ModelDownloadProgress> subscription,
  ) async {
    if (!_isTerminalDownloadProgress(progress.status)) return;

    await subscription.cancel();

    try {
      if (progress.status.isCompleted) {
        await _handleDownloadComplete(model);
        return;
      }

      await _cleanupFailedFreshDownload(model);
    } catch (e, s) {
      final failure = AppFailure.from(e, s);

      _extractionController.add(
        ModelDownloadProgress(
          modelId: model.uuid.value,
          status: DownloadStatus.failed,
          errorMessage: failure.message,
        ),
      );
    }
  }

  bool _isTerminalDownloadProgress(DownloadStatus status) {
    return status.isCompleted || status.isFailed || status.isCancelled;
  }

  /// Обработка завершения скачивания
  Future<void> _handleDownloadComplete(AsrModelEntity model) async {
    final modelId = model.uuid.value;

    // Получаем путь к скачанному архиву
    final archivePath = await _downloadManager.getDownloadedArchivePath(
      modelId,
    );

    if (archivePath == null) {
      await _cleanupFailedFreshDownload(model);
      _downloadManager.clearTask(modelId);

      _extractionController.add(
        ModelDownloadProgress(
          modelId: modelId,
          status: DownloadStatus.failed,
          errorMessage: 'Ошибка распаковки: путь до архива не найден',
        ),
      );

      return;
    }

    _extractionController.add(
      ModelDownloadProgress(
        modelId: modelId,
        status: DownloadStatus.extracting,
      ),
    );

    final hadDownloadedModel =
        await _localDataSource.getByModelId(modelId) != null;

    try {
      final modelsDir = await AsrModelPaths.modelsDir;
      final modelPath = await AsrModelPaths.modelPath(model.modelDirName);

      if (!hadDownloadedModel) {
        await _deleteModelDirectoryIfNotDownloaded(model);
      }

      await ArchiveExtractor.extractTarBz2(
        archivePath: archivePath,
        destinationDir: modelsDir,
      );

      final modelDirectory = Directory(modelPath);
      int totalSize = 0;

      if (modelDirectory.existsSync()) {
        await for (final entity in modelDirectory.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) totalSize += await entity.length();
        }
      }

      final downloadedModel = DownloadedModelObject(
        modelId: modelId,
        modelDirName: model.modelDirName,
        localPath: AsrModelPaths.modelRelativePath(model.modelDirName),
        downloadedAt: DateTime.now(),
        fileSizeBytes: totalSize,
      );
      await _localDataSource.save(downloadedModel);

      _downloadManager.clearTask(modelId);

      _extractionController.add(
        ModelDownloadProgress(
          modelId: modelId,
          status: DownloadStatus.completed,
        ),
      );
    } catch (e, s) {
      final failure = AppFailure.from(e, s);

      if (!hadDownloadedModel) await _deleteLocalRecordIfExists(modelId);
      await _cleanupFailedFreshDownload(model, archivePath: archivePath);
      _downloadManager.clearTask(modelId);

      _extractionController.add(
        ModelDownloadProgress(
          modelId: modelId,
          status: DownloadStatus.failed,
          errorMessage: 'Ошибка распаковки: ${failure.message}',
        ),
      );
    }
  }

  Future<void> _cleanupFailedFreshDownload(
    AsrModelEntity model, {
    String? archivePath,
  }) async {
    final resolvedArchivePath =
        archivePath ?? await AsrModelPaths.archivePath(model.modelDirName);
    await _deleteArchiveIfExists(resolvedArchivePath);

    await _deleteModelDirectoryIfNotDownloaded(model);
  }

  Future<void> _deleteModelDirectoryIfNotDownloaded(
    AsrModelEntity model,
  ) async {
    final downloadedModel = await _localDataSource.getByModelId(
      model.uuid.value,
    );
    if (downloadedModel != null) return;

    final modelPath = await AsrModelPaths.modelPath(model.modelDirName);
    await _deleteDirectoryIfExists(modelPath);
  }

  Future<void> _deleteArchiveIfExists(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (e, s) {
      AppFailure.from(e, s);
    }
  }

  Future<void> _deleteLocalRecordIfExists(String modelId) async {
    try {
      await _localDataSource.delete(modelId);
    } catch (e, s) {
      AppFailure.from(e, s);
    }
  }

  Future<void> _deleteDirectoryIfExists(String path) async {
    try {
      final directory = Directory(path);
      if (directory.existsSync()) await directory.delete(recursive: true);
    } catch (e, s) {
      AppFailure.from(e, s);
    }
  }

  @override
  Stream<ModelDownloadProgress> watchDownloadProgress(String uid) {
    return watchAllDownloads().where((progress) => progress.modelId == uid);
  }

  @override
  Stream<ModelDownloadProgress> watchAllDownloads() {
    final downloadProgress = _downloadManager.progressStream.where(
      (progress) => !progress.status.isCompleted,
    );

    return downloadProgress.mergeWith([_extractionController.stream]);
  }

  @override
  Future<void> cancelDownload(String uid) async {
    await _downloadManager.cancel(uid);
  }

  @override
  Future<void> pauseDownload(String uid) async {
    await _downloadManager.pause(uid);
  }

  @override
  Future<void> resumeDownload(String uid) async {
    await _downloadManager.resume(uid);
  }

  @override
  Future<void> deleteModel(String uid) async {
    // Получаем информацию о модели
    final model = await _localDataSource.getByModelId(uid);
    if (model == null) return;

    // Удаляем файлы с диска
    final fullPath = await AsrModelPaths.resolveRelativePath(model.localPath);
    final directory = Directory(fullPath);
    if (directory.existsSync()) await directory.delete(recursive: true);

    // Удаляем запись из БД
    await _localDataSource.delete(uid);
  }

  @override
  Future<void> selectModel(String uid) async {
    await _localDataSource.setSelected(uid);
  }

  @override
  Future<AsrModelEntity?> getSelectedModel() async {
    final selected = await _localDataSource.getSelected();
    if (selected == null) return null;

    // Находим соответствующую модель из списка доступных
    final selectedModel = AsrModelEntity.availableModels.firstWhereOrNull(
      (model) => model.uuid.value == selected.modelId,
    );

    return selectedModel?.copyWith(isDownloaded: true, isSelected: true);
  }

  @override
  Stream<List<AsrModelEntity>> watchModelsWithStatus() {
    return _localDataSource.watchAll().map((downloadedModels) {
      final downloadedMap = {
        for (final model in downloadedModels) model.modelId: model,
      };

      return [
        for (final model in AsrModelEntity.availableModels)
          model.copyWith(
            isDownloaded: downloadedMap.containsKey(model.uuid.value),
            isSelected: downloadedMap[model.uuid.value]?.isSelected ?? false,
          ),
      ];
    });
  }

  @override
  Stream<AsrModelEntity?> watchSelectedModel() {
    return _localDataSource.watchSelected().map((selected) {
      if (selected == null) return null;

      final selectedModel = AsrModelEntity.availableModels.firstWhereOrNull(
        (model) => model.uuid.value == selected.modelId,
      );

      return selectedModel?.copyWith(isDownloaded: true, isSelected: true);
    });
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
  Future<bool> isModelDownloaded(String uid) async {
    final model = await _localDataSource.getByModelId(uid);
    if (model == null) return false;

    // Дополнительно проверяем наличие файлов
    return _localDataSource.verifyModelFiles(uid);
  }

  @override
  Future<String?> getModelPath(String uid) async {
    final model = await _localDataSource.getByModelId(uid);
    if (model == null) return null;

    // Проверяем наличие файлов
    final exists = await _localDataSource.verifyModelFiles(uid);
    if (!exists) {
      // Файлы удалены - очищаем БД
      await _localDataSource.delete(uid);
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
