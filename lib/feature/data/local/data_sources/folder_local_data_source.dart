import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/error/app_exception.dart';
import 'package:voice_notes/core/packages/db/object_box/dao/dao.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';

/// Локальный источник данных для работы с папками
abstract interface class FolderLocalDataSource {
  /// Получить все папки, отсортированные по updatedAt DESC
  Future<List<FolderObject>> getAll();

  /// Получить папку по UID
  Future<FolderObject> getByUid(String uid);

  /// Сохранить новую папку
  Future<FolderObject> save(FolderObject folder);

  /// Обновить существующую папку
  Future<FolderObject> update(FolderObject folder);

  // Disabled intentionally: direct folder delete without cascading notes/audio
  // is unsafe for the current data model. Use deleteWithNotes instead.
  // Future<void> delete(String uid);

  /// Удалить папку вместе со всеми заметками и связанными аудиофайлами.
  ///
  /// Возвращает список относительных путей удалённых аудиофайлов.
  Future<List<String>> deleteWithNotes(String uid);

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

  static const _folderDao = FolderDao();

  FolderLocalDataSourceImpl(this._db);

  @override
  Future<List<FolderObject>> getAll() async => _folderDao.findAll(_db.box);

  @override
  Future<FolderObject> getByUid(String uid) async {
    return _folderDao
        .findByUid(_db.box, uid)
        .orThrowNotFound(EntityType.folder, uid);
  }

  @override
  Future<FolderObject> save(FolderObject folder) async {
    return _folderDao.put(_db.box, folder, mode: PutMode.insert);
  }

  @override
  Future<FolderObject> update(FolderObject folder) async {
    return _folderDao.put(_db.box, folder, mode: PutMode.update);
  }

  // Disabled intentionally: direct folder delete without cascading notes/audio
  // leaves too much room for accidental misuse. Keep deleteWithNotes as the
  // only supported path.
  // Future<void> delete(String uid) async {
  //   final folder = _folderDao.findByUid(_db.box, uid);
  //   if (folder != null) _folderDao.remove(_db.box, folder.id);
  // }

  @override
  Future<List<String>> deleteWithNotes(String uid) async {
    return _db.runInTransactionAsync((Store store, String uid) {
      final box = store.box;
      final folder = _folderDao.findByUid(box, uid);
      if (folder == null) return const <String>[];

      return _folderDao.removeWithNotes(box, folder);
    }, param: uid);
  }

  @override
  Future<int> getNotesCount(int folderId) async {
    return _folderDao.getNotesCount(_db.box, folderId);
  }

  @override
  Stream<List<FolderObject>> watchAll() {
    return _folderDao
        .queryAll(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  @override
  Stream<FolderObject?> watchByUid(String uid) {
    return _folderDao
        .queryByUid(_db.box, uid)
        .watch(triggerImmediately: true)
        .map((q) => q.findFirst());
  }
}
