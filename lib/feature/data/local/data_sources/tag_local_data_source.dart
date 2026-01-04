import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/db/object_box/dao/dao.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';

/// Локальный источник данных для работы с тегами
abstract interface class TagLocalDataSource {
  /// Получить все теги
  Future<List<TagObject>> getAll();

  /// Получить тег по ID
  Future<TagObject> getById(int id);

  /// Получить тег по имени (case-insensitive)
  Future<TagObject?> getByName(String name);

  /// Сохранить новый тег
  Future<TagObject> save(TagObject tag);

  /// Получить или создать тег по имени
  Future<TagObject> getOrCreate(String name, {int? colorValue});

  Future<List<TagObject>> saveMany(List<String> names);

  /// Удалить тег по имени
  Future<void> deleteByName(String name);

  /// Стрим всех тегов с реактивными обновлениями
  Stream<List<TagObject>> watchAll();
}

/// Реализация на основе ObjectBox
@Singleton(as: TagLocalDataSource)
class TagLocalDataSourceImpl implements TagLocalDataSource {
  final DatabaseClient _db;

  static const _tagDao = TagDao();

  TagLocalDataSourceImpl(this._db);

  @override
  Future<List<TagObject>> getAll() async => _tagDao.findAll(_db.box);

  ///TODO: Позже добавить выброс ошибки "Тег не найден"
  @override
  Future<TagObject> getById(int id) async => _tagDao.findById(_db.box, id)!;

  @override
  Future<TagObject?> getByName(String name) async =>
      _tagDao.findByName(_db.box, name);

  @override
  Future<TagObject> save(TagObject tag) async => _tagDao.put(_db.box, tag);

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

    return _tagDao.putMany(_db.box, tags);
  }

  @override
  Future<void> deleteByName(String name) async {
    final tag = await getByName(name);
    if (tag != null) _tagDao.remove(_db.box, tag.id);
  }

  @override
  Stream<List<TagObject>> watchAll() {
    return _tagDao
        .queryAll(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }
}
