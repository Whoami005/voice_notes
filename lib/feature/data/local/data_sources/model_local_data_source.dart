import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/core/packages/path/asr_model_paths.dart';
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

  /// Стрим всех скачанных моделей с реактивными обновлениями
  Stream<List<DownloadedModelObject>> watchAll();

  /// Стрим выбранной модели с реактивными обновлениями
  Stream<DownloadedModelObject?> watchSelected();
}

/// Реализация на основе ObjectBox
@Singleton(as: ModelLocalDataSource)
class ModelLocalDataSourceImpl implements ModelLocalDataSource {
  final DatabaseClient _db;

  Box<DownloadedModelObject> get _modelBox => _db.box<DownloadedModelObject>();

  ModelLocalDataSourceImpl(this._db);

  @override
  Future<List<DownloadedModelObject>> getAll() async {
    return _modelBox.getAll();
  }

  @override
  Future<DownloadedModelObject?> getByModelId(String modelId) async {
    final query = _modelBox
        .query(DownloadedModelObject_.modelId.equals(modelId))
        .build();
    final result = query.findFirst();
    query.close();

    return result;
  }

  @override
  Future<void> save(DownloadedModelObject model) async {
    _modelBox.put(model);
  }

  @override
  Future<void> delete(String modelId) async {
    final model = await getByModelId(modelId);
    if (model != null) {
      _modelBox.remove(model.id);
    }
  }

  @override
  Future<void> setSelected(String modelId) async {
    _db.runInTransaction(() {
      // Снимаем выбор с текущей выбранной модели
      final selectedQuery = _modelBox
          .query(DownloadedModelObject_.isSelected.equals(true))
          .build();
      final selected = selectedQuery.findFirst();
      selectedQuery.close();

      if (selected != null) {
        selected.isSelected = false;
        _modelBox.put(selected);
      }

      // Устанавливаем новую выбранную модель
      final modelQuery = _modelBox
          .query(DownloadedModelObject_.modelId.equals(modelId))
          .build();
      final model = modelQuery.findFirst();
      modelQuery.close();

      if (model != null) {
        model.isSelected = true;
        _modelBox.put(model);
      }
    });
  }

  @override
  Future<DownloadedModelObject?> getSelected() async {
    final query = _modelBox
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
      _modelBox.put(selected);
    }
  }

  @override
  Future<bool> verifyModelFiles(String modelId) async {
    final model = await getByModelId(modelId);
    if (model == null) return false;

    final fullPath = await AsrModelPaths.resolveRelativePath(model.localPath);
    final directory = Directory(fullPath);
    if (!directory.existsSync()) return false;

    // Проверяем что директория не пустая
    final files = directory.listSync();
    return files.isNotEmpty;
  }

  @override
  Stream<List<DownloadedModelObject>> watchAll() {
    return _modelBox
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }

  @override
  Stream<DownloadedModelObject?> watchSelected() {
    return _modelBox
        .query(DownloadedModelObject_.isSelected.equals(true))
        .watch(triggerImmediately: true)
        .map((query) => query.findFirst());
  }
}
