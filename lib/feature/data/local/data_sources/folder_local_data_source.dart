import 'package:injectable/injectable.dart' hide Order;
import 'package:objectbox/objectbox.dart' show Order;
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart'
    hide Order;
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';

/// Локальный источник данных для работы с папками
abstract interface class FolderLocalDataSource {
  /// Получить все папки, отсортированные по updatedAt DESC
  Future<List<FolderObject>> getAll();

  /// Получить папку по UID
  Future<FolderObject?> getByUid(String uid);

  /// Получить папку по UID (синхронно, для транзакций)
  FolderObject? getByUidSync(String uid);

  /// Сохранить новую папку
  Future<FolderObject> save(FolderObject folder);

  /// Обновить существующую папку
  Future<FolderObject> update(FolderObject folder);

  /// Удалить папку по UID
  Future<void> delete(String uid);

  /// Удалить папку вместе со всеми заметками (каскадное удаление)
  Future<void> deleteWithNotes(String uid);

  /// Получить количество заметок в папке
  Future<int> getNotesCount(int folderId);

  /// Стрим всех папок с реактивными обновлениями
  Stream<List<FolderObject>> watchAll();

  /// Стрим папки по UID с реактивными обновлениями
  Stream<FolderObject?> watchByUid(String uid);
}

/// Реализация на основе ObjectBox
@Singleton(as: FolderLocalDataSource)
class FolderLocalDataSourceImpl implements FolderLocalDataSource {
  final DatabaseClient _db;

  Box<FolderObject> get _folderBox => _db.box<FolderObject>();

  FolderLocalDataSourceImpl(this._db);

  @override
  Future<List<FolderObject>> getAll() async {
    final query = _folderBox
        .query()
        .order(FolderObject_.updatedAt, flags: Order.descending)
        .build();
    final result = query.find();
    query.close();

    return result;
  }

  @override
  Future<FolderObject?> getByUid(String uid) async {
    final query = _folderBox.query(FolderObject_.uid.equals(uid)).build();
    final result = query.findFirst();
    query.close();

    return result;
  }

  @override
  FolderObject? getByUidSync(String uid) {
    final query = _folderBox.query(FolderObject_.uid.equals(uid)).build();
    final result = query.findFirst();
    query.close();

    return result;
  }

  @override
  Future<FolderObject> save(FolderObject folder) async {
    return _folderBox.putAndGetAsync(folder, mode: PutMode.insert);
  }

  @override
  Future<FolderObject> update(FolderObject folder) async {
    return _folderBox.putAndGetAsync(folder, mode: PutMode.update);
  }

  @override
  Future<void> delete(String uid) async {
    final folder = await getByUid(uid);

    if (folder != null) _folderBox.remove(folder.id);
  }

  @override
  Future<void> deleteWithNotes(String uid) async {
    await _db.runInTransactionAsync((Store store, String uid) async {
      final folderBox = store.box<FolderObject>();
      final noteBox = store.box<NoteObject>();

      final query = folderBox.query(FolderObject_.uid.equals(uid)).build();
      final folder = query.findFirst();
      query.close();

      if (folder == null) return;

      final noteIds = [for (final note in folder.notes) note.id];
      await noteBox.removeManyAsync(noteIds);

      folderBox.remove(folder.id);
    }, param: uid);
  }

  @override
  Future<int> getNotesCount(int folderId) async {
    final folder = _folderBox.get(folderId);
    return folder?.notes.length ?? 0;
  }

  @override
  Stream<List<FolderObject>> watchAll() {
    return _folderBox
        .query()
        .order(FolderObject_.updatedAt, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }

  @override
  Stream<FolderObject?> watchByUid(String uid) {
    return _folderBox
        .query(FolderObject_.uid.equals(uid))
        .watch(triggerImmediately: true)
        .map((query) => query.findFirst());
  }
}
