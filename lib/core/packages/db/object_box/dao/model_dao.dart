import 'package:objectbox/objectbox.dart' show Order;
import 'package:voice_notes/core/packages/db/object_box/dao/box_provider.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart'
    hide Order;
import 'package:voice_notes/feature/data/local/models/downloaded_model_object.dart';

/// DAO для работы со скачанными моделями
class ModelDao {
  const ModelDao();

  /// Найти все модели, отсортированные по downloadedAt DESC
  List<DownloadedModelObject> findAll(BoxProvider box) {
    final query = box<DownloadedModelObject>()
        .query()
        .order(DownloadedModelObject_.downloadedAt, flags: Order.descending)
        .build();

    final result = query.find();
    query.close();

    return result;
  }

  /// Найти модель по modelId
  DownloadedModelObject? findByModelId(BoxProvider box, String modelId) {
    final query = box<DownloadedModelObject>()
        .query(DownloadedModelObject_.modelId.equals(modelId))
        .build();

    final result = query.findFirst();
    query.close();

    return result;
  }

  /// Найти выбранную модель
  DownloadedModelObject? findSelected(BoxProvider box) {
    final query = box<DownloadedModelObject>()
        .query(DownloadedModelObject_.isSelected.equals(true))
        .build();

    final result = query.findFirst();
    query.close();

    return result;
  }

  /// Сохранить или обновить модель
  DownloadedModelObject put(
    BoxProvider box,
    DownloadedModelObject model, {
    PutMode mode = PutMode.put,
  }) {
    box<DownloadedModelObject>().put(model, mode: mode);
    return model;
  }

  /// Удалить модель по ID
  void remove(BoxProvider box, int id) =>
      box<DownloadedModelObject>().remove(id);

  /// Снять выбор со всех моделей и установить новую выбранную
  void setSelected(BoxProvider box, String modelId) {
    final currentSelected = findSelected(box);
    if (currentSelected != null) {
      currentSelected.isSelected = false;
      put(box, currentSelected);
    }

    final model = findByModelId(box, modelId);
    if (model != null) {
      model.isSelected = true;
      put(box, model);
    }
  }

  /// Снять выбор с текущей выбранной модели
  void clearSelection(BoxProvider box) {
    final selected = findSelected(box);

    if (selected != null) {
      selected.isSelected = false;
      put(box, selected);
    }
  }

  // === Query Builders для watch ===

  /// Query builder для всех моделей
  QueryBuilder<DownloadedModelObject> queryAll(BoxProvider box) {
    return box<DownloadedModelObject>().query().order(
      DownloadedModelObject_.downloadedAt,
      flags: Order.descending,
    );
  }

  /// Query builder для выбранной модели
  QueryBuilder<DownloadedModelObject> querySelected(BoxProvider box) {
    return box<DownloadedModelObject>().query(
      DownloadedModelObject_.isSelected.equals(true),
    );
  }
}
