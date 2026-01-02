import 'package:injectable/injectable.dart' hide Order;
import 'package:objectbox/objectbox.dart' show Order;
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart'
    hide Order;
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';

/// Локальный источник данных для работы с папками
abstract interface class FolderLocalDataSource {
  /// Получить все папки, отсортированные по updatedAt DESC
  Future<List<FolderObject>> getAll();

  /// Получить папку по UID
  Future<FolderObject?> getByUid(String uid);

  /// Сохранить новую папку
  Future<FolderObject> save(FolderObject folder);

  /// Обновить существующую папку
  Future<FolderObject> update(FolderObject folder);

  /// Удалить папку по UID
  Future<void> delete(String uid);

  /// Получить количество заметок в папке
  Future<int> getNotesCount(int folderId);
}

/// Реализация на основе ObjectBox
@Singleton(as: FolderLocalDataSource)
class FolderLocalDataSourceImpl implements FolderLocalDataSource {
  final DatabaseClient _db;

  FolderLocalDataSourceImpl(this._db);

  @override
  Future<List<FolderObject>> getAll() async {
    final query = _db
        .box<FolderObject>()
        .query()
        .order(FolderObject_.updatedAt, flags: Order.descending)
        .build();
    final result = query.find();
    query.close();

    return result;
  }

  @override
  Future<FolderObject?> getByUid(String uid) async {
    final query = _db
        .box<FolderObject>()
        .query(FolderObject_.uid.equals(uid))
        .build();
    final result = query.findFirst();
    query.close();

    return result;
  }

  @override
  Future<FolderObject> save(FolderObject folder) async {
    return _db.box<FolderObject>().putAndGetAsync(folder, mode: PutMode.insert);
  }

  @override
  Future<FolderObject> update(FolderObject folder) async {
    return _db.box<FolderObject>().putAndGetAsync(folder, mode: PutMode.update);
  }

  @override
  Future<void> delete(String uid) async {
    final folder = await getByUid(uid);

    if (folder != null) _db.box<FolderObject>().remove(folder.id);
  }

  @override
  Future<int> getNotesCount(int folderId) async {
    final folder = _db.box<FolderObject>().get(folderId);
    return folder?.notes.length ?? 0;
  }
}
