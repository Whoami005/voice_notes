import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/db/object_box/dao/dao.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/core/packages/path/asr_model_paths.dart';
import 'package:voice_notes/feature/data/local/models/downloaded_model_object.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Локальный источник данных для работы со скачанными моделями
abstract interface class ModelLocalDataSource {
  /// Получить все скачанные модели
  Future<List<DownloadedModelObject>> getAll();

  /// Получить модель по её ID
  Future<DownloadedModelObject?> getByModelId(String modelId);

  /// Сохранить информацию о скачанной модели
  Future<void> save(DownloadedModelObject model);

  /// Удалить модель по ID
  Future<void> delete(String modelId);

  /// Установить модель как выбранную (активную)
  /// Снимает выбор с предыдущей модели
  Future<void> setSelected(String modelId);

  /// Получить выбранную модель
  Future<DownloadedModelObject?> getSelected();

  /// Снять выбор со всех моделей
  Future<void> clearSelection();

  /// Проверить существование файлов модели на диске
  Future<bool> verifyModelFiles(String modelId);

  /// Стрим всех скачанных моделей с реактивными обновлениями
  Stream<List<DownloadedModelObject>> watchAll();

  /// Стрим выбранной модели с реактивными обновлениями
  Stream<DownloadedModelObject?> watchSelected();
}

/// Реализация на основе ObjectBox
@Singleton(as: ModelLocalDataSource)
class ModelLocalDataSourceImpl implements ModelLocalDataSource {
  final DatabaseClient _db;

  static const _modelDao = ModelDao();

  ModelLocalDataSourceImpl(this._db);

  @override
  Future<List<DownloadedModelObject>> getAll() async =>
      _modelDao.findAll(_db.box);

  @override
  Future<DownloadedModelObject?> getByModelId(String modelId) async {
    return _modelDao.findByModelId(_db.box, modelId);
  }

  @override
  Future<void> save(DownloadedModelObject model) async {
    _modelDao.put(_db.box, model);
  }

  @override
  Future<void> delete(String modelId) async {
    final model = await getByModelId(modelId);
    if (model != null) _modelDao.remove(_db.box, model.id);
  }

  @override
  Future<void> setSelected(String modelId) async {
    _db.runInTransaction(() => _modelDao.setSelected(_db.box, modelId));
  }

  @override
  Future<DownloadedModelObject?> getSelected() async {
    return _modelDao.findSelected(_db.box);
  }

  @override
  Future<void> clearSelection() async {
    _modelDao.clearSelection(_db.box);
  }

  @override
  Future<bool> verifyModelFiles(String modelId) async {
    final model = await getByModelId(modelId);
    if (model == null) return false;

    final fullPath = await AsrModelPaths.resolveRelativePath(model.localPath);
    final directory = Directory(fullPath);
    if (!directory.existsSync()) return false;

    final entity = _findEntityByModelId(modelId);
    if (entity == null) return directory.listSync().isNotEmpty;

    // Защищает от частично/битых скачиваний (актуально для
    // Parakeet-bundle'ов по ~640 МБ).
    return entity.getModelFiles().allFileNames.every(
      (name) => _isValidFile('$fullPath/$name'),
    );
  }

  bool _isValidFile(String path) {
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 0;
  }

  AsrModelEntity? _findEntityByModelId(String modelId) {
    for (final entity in AsrModelEntity.availableModels) {
      if (entity.uuid.value == modelId) return entity;
    }
    return null;
  }

  @override
  Stream<List<DownloadedModelObject>> watchAll() {
    return _modelDao
        .queryAll(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  @override
  Stream<DownloadedModelObject?> watchSelected() {
    return _modelDao
        .querySelected(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.findFirst());
  }
}
