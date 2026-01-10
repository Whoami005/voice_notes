import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/downloader/download_manager.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/core/packages/internet/internet_checker.dart';
import 'package:voice_notes/core/packages/storage/storage_checker.dart';
import 'package:voice_notes/core/state/async/initializable_async_cubits.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';

part 'models_state.dart';

/// Cubit для управления ASR моделями
class ModelsCubit extends RefreshableAsyncCubit<ModelsState> {
  final ModelRepository _repository;
  final AsrService _asrService;

  StreamSubscription<ModelDownloadProgress>? _downloadSubscription;

  ModelsCubit({
    required ModelRepository repository,
    required AsrService asrService,
  }) : _repository = repository,
       _asrService = asrService;

  @override
  Future<void> init() async {
    await load(() async {
      // Верифицируем модели на диске
      await _repository.verifyAllModels();

      // Загружаем список моделей с актуальным статусом
      final models = await _repository.getModelsWithStatus();

      // Подписываемся на обновления прогресса
      _subscribeToDownloads();

      return ModelsState(models: models);
    });
  }

  @override
  Future<void> refresh() async {
    await transform((current) async {
      await _repository.verifyAllModels();
      final models = await _repository.getModelsWithStatus();

      return current.copyWith(models: models);
    });
  }

  /// Подписка на обновления прогресса скачивания
  void _subscribeToDownloads() {
    _downloadSubscription?.cancel();
    _downloadSubscription = _repository.watchAllDownloads().listen(
      _handleDownloadProgress,
      onError: addError,
      cancelOnError: false,
    );
  }

  /// Обработка обновления прогресса
  void _handleDownloadProgress(ModelDownloadProgress progress) {
    whenData((current) {
      // Обновляем map прогресса
      final newDownloads = {...current.downloads, progress.modelId: progress};

      // Если скачивание завершено — обновляем список моделей
      if (progress.status.isCompleted) {
        _refreshModelsAfterDownload(progress.modelId, newDownloads);
        return;
      }

      // Если ошибка или отмена — удаляем из активных загрузок через
      // некоторое время
      if (progress.status.isFailed || progress.status.isCancelled) {
        emitSuccess(current.copyWith(downloads: newDownloads));

        // Удаляем из downloads через 3 секунды
        Future.delayed(const Duration(seconds: 3), () {
          whenData((state) {
            final updated = {...state.downloads}..remove(progress.modelId);
            emitSuccess(state.copyWith(downloads: updated));
          });
        });
        return;
      }

      emitSuccess(current.copyWith(downloads: newDownloads));
    });
  }

  /// Обновить список моделей после успешного скачивания
  Future<void> _refreshModelsAfterDownload(
    String modelId,
    Map<String, ModelDownloadProgress> currentDownloads,
  ) async {
    await transform((current) async {
      final models = await _repository.getModelsWithStatus();
      final newDownloads = {...currentDownloads}..remove(modelId);

      return current.copyWith(models: models, downloads: newDownloads);
    });
  }

  /// Скачать модель
  ///
  /// Выполняет проверки перед скачиванием:
  /// 1. Подключение к интернету
  /// 2. Достаточно места на устройстве
  Future<AppFailure?> downloadModel(AsrModelEntity model) async {
    // Проверяем интернет
    final hasConnection = await InternetChecker.hasConnection();
    if (!hasConnection) return const NetworkFailure.noConnection();

    // Парсим размер модели для проверки места
    final requiredBytes = _parseModelSize(model.size);
    if (requiredBytes != null) {
      // Нужно место для архива + распакованной модели + буфер
      final totalRequired = (requiredBytes * 2.2).toInt();
      final hasSpace = await StorageChecker.hasEnoughSpace(totalRequired);

      if (!hasSpace) {
        final available = await StorageChecker.getAvailableSpace();

        return StorageFailure.insufficientSpace(
          requiredBytes: totalRequired,
          availableBytes: available,
        );
      }
    }

    // Запускаем скачивание
    await execute(
      action: () => _repository.downloadModel(model),
      onError: (failure) {
        // Обновляем прогресс с ошибкой
        _handleDownloadProgress(
          ModelDownloadProgress(
            modelId: model.uuid,
            status: DownloadStatus.failed,
            errorMessage: failure.message,
          ),
        );
      },
    );

    return null;
  }

  /// Парсинг размера модели из строки (например "466 MB" -> bytes)
  int? _parseModelSize(String sizeStr) {
    final regex = RegExp(r'([\d.]+)\s*(MB|GB|KB)', caseSensitive: false);
    final match = regex.firstMatch(sizeStr);
    if (match == null) return null;

    final value = double.tryParse(match.group(1) ?? '');
    if (value == null) return null;

    final unit = match.group(2)?.toUpperCase();
    return switch (unit) {
      'KB' => (value * 1024).toInt(),
      'MB' => (value * 1024 * 1024).toInt(),
      'GB' => (value * 1024 * 1024 * 1024).toInt(),
      _ => null,
    };
  }

  /// Отменить скачивание
  Future<void> cancelDownload(String modelId) async {
    await execute(action: () => _repository.cancelDownload(modelId));
  }

  /// Приостановить скачивание
  Future<void> pauseDownload(String modelId) async {
    await execute(action: () => _repository.pauseDownload(modelId));
  }

  /// Возобновить скачивание
  Future<void> resumeDownload(String modelId) async {
    await execute(action: () => _repository.resumeDownload(modelId));
  }

  /// Удалить модель
  Future<void> deleteModel(String modelId) async {
    await transform((current) async {
      // Если удаляем активную модель — освобождаем ASR сервис
      await _disposeAsrModel(current.selectedModel, modelId);

      await _repository.deleteModel(modelId);

      // Обновляем список
      final models = await _repository.getModelsWithStatus();

      return current.copyWith(models: models);
    });
  }

  /// Выбрать модель как активную
  Future<void> selectModel(AsrModelEntity newModel) async {
    await transform((current) async {
      // Переинициализируем ASR сервис с новой моделью
      await _switchAsrModel(newModel);

      await _repository.selectModel(newModel.uuid);

      // Обновляем список
      final models = await _repository.getModelsWithStatus();

      return current.copyWith(models: models);
    });
  }

  Future<void> _switchAsrModel(AsrModelEntity newModel) async {
    final modelPath = await _repository.getModelPath(newModel.uuid);
    if (modelPath != null) await _asrService.switchModel(newModel, modelPath);
  }

  Future<void> _disposeAsrModel(
    AsrModelEntity? selectedModel,
    String modelId,
  ) async {
    final isSelectedModel = selectedModel?.uuid == modelId;
    if (isSelectedModel) await _asrService.dispose();
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
