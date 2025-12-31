import 'dart:io';

import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/downloaded_model_object.dart';

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
}

/// Реализация на основе ObjectBox
class ModelLocalDataSourceImpl implements ModelLocalDataSource {
  final DatabaseClient _db;

  ModelLocalDataSourceImpl(this._db);

  @override
  Future<List<DownloadedModelObject>> getAll() async {
    return _db.box<DownloadedModelObject>().getAll();
  }

  @override
  Future<DownloadedModelObject?> getByModelId(String modelId) async {
    final query = _db
        .box<DownloadedModelObject>()
        .query(DownloadedModelObject_.modelId.equals(modelId))
        .build();
    final result = query.findFirst();
    query.close();

    return result;
  }

  @override
  Future<void> save(DownloadedModelObject model) async {
    _db.box<DownloadedModelObject>().put(model);
  }

  @override
  Future<void> delete(String modelId) async {
    final model = await getByModelId(modelId);
    if (model != null) {
      _db.box<DownloadedModelObject>().remove(model.id);
    }
  }

  @override
  Future<void> setSelected(String modelId) async {
    // Снимаем выбор со всех моделей
    await clearSelection();

    // Устанавливаем выбранную модель
    final model = await getByModelId(modelId);
    if (model != null) {
      model.isSelected = true;
      _db.box<DownloadedModelObject>().put(model);
    }
  }

  @override
  Future<DownloadedModelObject?> getSelected() async {
    final query = _db
        .box<DownloadedModelObject>()
        .query(DownloadedModelObject_.isSelected.equals(true))
        .build();
    final result = query.findFirst();
    query.close();

    return result;
  }

  @override
  Future<void> clearSelection() async {
    final selected = await getSelected();
    if (selected != null) {
      selected.isSelected = false;
      _db.box<DownloadedModelObject>().put(selected);
    }
  }

  @override
  Future<bool> verifyModelFiles(String modelId) async {
    final model = await getByModelId(modelId);
    if (model == null) return false;

    final directory = Directory(model.localPath);
    if (!directory.existsSync()) return false;

    // Проверяем что директория не пустая
    final files = directory.listSync();
    return files.isNotEmpty;
  }
}
