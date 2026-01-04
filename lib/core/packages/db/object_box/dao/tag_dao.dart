import 'package:voice_notes/core/packages/db/object_box/dao/box_provider.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';

/// DAO для работы с тегами
class TagDao {
  const TagDao();

  /// Найти все теги
  List<TagObject> findAll(BoxProvider box) => box<TagObject>().getAll();

  /// Найти тег по ID
  TagObject? findById(BoxProvider box, int id) => box<TagObject>().get(id);

  /// Найти тег по имени (case-insensitive)
  TagObject? findByName(BoxProvider box, String name) {
    final normalizedName = name.toLowerCase().trim();
    final query =
        box<TagObject>().query(TagObject_.name.equals(normalizedName)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  /// Сохранить или обновить тег
  TagObject put(BoxProvider box, TagObject tag) {
    box<TagObject>().put(tag);
    return tag;
  }

  /// Создать или обновить теги
  List<TagObject> putMany(BoxProvider box, List<TagObject> tags) {
    box<TagObject>().putMany(tags, mode: PutMode.put);
    return tags;
  }

  /// Удалить тег по ID
  void remove(BoxProvider box, int id) => box<TagObject>().remove(id);

  // === Query Builders для watch ===

  /// Query builder для всех тегов
  QueryBuilder<TagObject> queryAll(BoxProvider box) => box<TagObject>().query();
}
