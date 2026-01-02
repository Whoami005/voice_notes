import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';

/// Локальный источник данных для работы с тегами
abstract interface class TagLocalDataSource {
  /// Получить все теги
  Future<List<TagObject>> getAll();

  /// Получить тег по ID
  Future<TagObject?> getById(int id);

  /// Получить тег по имени (case-insensitive)
  Future<TagObject?> getByName(String name);

  /// Сохранить новый тег
  Future<TagObject> save(TagObject tag);

  /// Получить или создать тег по имени
  Future<TagObject> getOrCreate(String name, {int? colorValue});

  Future<List<TagObject>> saveMany(List<String> names);

  /// Удалить тег по ID
  Future<void> delete(int id);

  /// Стрим всех тегов с реактивными обновлениями
  Stream<List<TagObject>> watchAll();
}

/// Реализация на основе ObjectBox
@Singleton(as: TagLocalDataSource)
class TagLocalDataSourceImpl implements TagLocalDataSource {
  final DatabaseClient _db;

  Box<TagObject> get _tagBox => _db.box<TagObject>();

  TagLocalDataSourceImpl(this._db);

  @override
  Future<List<TagObject>> getAll() async {
    return _tagBox.getAll();
  }

  @override
  Future<TagObject?> getById(int id) async {
    return _tagBox.get(id);
  }

  @override
  Future<TagObject?> getByName(String name) async {
    final normalizedName = name.toLowerCase().trim();
    final query = _tagBox.query(TagObject_.name.equals(normalizedName)).build();
    final result = query.findFirst();
    query.close();

    return result;
  }

  @override
  Future<TagObject> save(TagObject tag) async {
    return _tagBox.putAndGetAsync(tag);
  }

  @override
  Future<TagObject> getOrCreate(String name, {int? colorValue}) async {
    final existing = await getByName(name);
    if (existing != null) return existing;

    final tag = TagObject(
      name: name.toLowerCase().trim(),
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );

    return save(tag);
  }

  @override
  Future<List<TagObject>> saveMany(List<String> names) async {
    final tags = [
      for (final name in names)
        TagObject(name: name.toLowerCase().trim(), createdAt: DateTime.now()),
    ];

    return _tagBox.putAndGetManyAsync(tags, mode: PutMode.put);
  }

  @override
  Future<void> delete(int id) async {
    _tagBox.remove(id);
  }

  @override
  Stream<List<TagObject>> watchAll() {
    return _tagBox
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }
}
