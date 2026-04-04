part of 'models_cubit.dart';

/// Состояние экрана управления моделями
class ModelsState extends Equatable {
  /// Список всех доступных моделей с их текущим статусом
  final List<AsrModelEntity> models;

  /// Прогресс скачивания для каждой модели (modelId -> progress)
  final Map<String, ModelDownloadProgress> downloads;

  const ModelsState({this.models = const [], this.downloads = const {}});

  /// Получить выбранную модель
  AsrModelEntity? get selectedModel =>
      models.firstWhereOrNull((model) => model.isSelected);

  /// Скачанные модели
  List<AsrModelEntity> get downloadedModels => [
    for (final model in models)
      if (model.isDownloaded) model,
  ];

  /// Модели в процессе скачивания
  List<AsrModelEntity> get downloadingModels {
    final result = <AsrModelEntity>[];

    for (final model in models) {
      final progress = downloads[model.uuid.value];

      if (progress != null && _isActiveDownload(progress.status)) {
        result.add(model);
      }
    }

    return result;
  }

  bool _isActiveDownload(DownloadStatus status) {
    return status == DownloadStatus.queued ||
        status == DownloadStatus.downloading ||
        status == DownloadStatus.extracting ||
        status == DownloadStatus.paused;
  }

  /// Получить прогресс скачивания для модели
  ModelDownloadProgress? getDownloadProgress(String modelId) =>
      downloads[modelId];

  /// Проверить, активна ли загрузка модели
  bool isDownloading(String modelId) {
    final progress = downloads[modelId];
    if (progress == null) return false;

    return _isActiveDownload(progress.status);
  }

  ModelsState copyWith({
    List<AsrModelEntity>? models,
    Map<String, ModelDownloadProgress>? downloads,
  }) {
    return ModelsState(
      models: models ?? this.models,
      downloads: downloads ?? this.downloads,
    );
  }

  @override
  List<Object?> get props => [models, downloads];
}
