import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/downloader/download_manager.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/core/packages/internet/internet_checker.dart';
import 'package:voice_notes/core/packages/storage/storage_checker.dart';
import 'package:voice_notes/core/state/base_cubit.dart';
import 'package:voice_notes/core/state/initializable.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';

part 'models_state.dart';

/// Cubit для управления ASR моделями
class ModelsCubit extends BaseCubit<ModelsState> implements Refreshable {
  final ModelRepository _repository;

  StreamSubscription<ModelDownloadProgress>? _downloadSubscription;

  ModelsCubit({required ModelRepository repository}) : _repository = repository;

  @override
  Future<void> init() async {
    await guard(() async {
      // Верифицируем модели на диске
      await _repository.verifyAllModels();

      // Загружаем список моделей с актуальным статусом
      final models = await _repository.getModelsWithStatus();

      // Получаем выбранную модель
      final selected = await _repository.getSelectedModel();

      // Подписываемся на обновления прогресса
      _subscribeToDownloads();

      return ModelsState(models: models, selectedModelId: selected?.id);
    });
  }

  @override
  Future<void> refresh() async {
    await safeExecute(
      action: () async {
        await updateAsync((current) async {
          await _repository.verifyAllModels();
          final models = await _repository.getModelsWithStatus();
          final selected = await _repository.getSelectedModel();

          return current.copyWith(
            models: models,
            selectedModelId: selected?.id,
            clearSelectedModelId: selected == null,
          );
        });
      },
    );
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
    withData((current) {
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
          update(
            (state) => state.copyWith(
              downloads: {...state.downloads}..remove(progress.modelId),
            ),
          );
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
    await updateAsync((current) async {
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
    await safeExecute(
      action: () => _repository.downloadModel(model),
      onError: (failure) {
        // Обновляем прогресс с ошибкой
        _handleDownloadProgress(
          ModelDownloadProgress(
            modelId: model.id,
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
    await safeExecute(action: () => _repository.cancelDownload(modelId));
  }

  /// Приостановить скачивание
  Future<void> pauseDownload(String modelId) async {
    await safeExecute(action: () => _repository.pauseDownload(modelId));
  }

  /// Возобновить скачивание
  Future<void> resumeDownload(String modelId) async {
    await safeExecute(action: () => _repository.resumeDownload(modelId));
  }

  /// Удалить модель
  Future<void> deleteModel(String modelId) async {
    await safeExecute(
      action: () async {
        await _repository.deleteModel(modelId);

        // Обновляем список
        final models = await _repository.getModelsWithStatus();

        update((current) {
          // Если удалили выбранную модель — сбрасываем выбор
          final clearSelection = current.selectedModelId == modelId;

          return current.copyWith(
            models: models,
            clearSelectedModelId: clearSelection,
          );
        });
      },
    );
  }

  /// Выбрать модель как активную
  Future<void> selectModel(String modelId) async {
    await safeExecute(
      action: () async {
        await _repository.selectModel(modelId);

        update((current) {
          // Обновляем isSelected во всех моделях
          final updatedModels = <AsrModelEntity>[
            for (final model in current.models)
              model.copyWith(isSelected: model.id == modelId),
          ];

          return current.copyWith(
            models: updatedModels,
            selectedModelId: modelId,
          );
        });
      },
    );
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
