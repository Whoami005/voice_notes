import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/error/app_exception.dart';
import 'package:voice_notes/core/packages/db/object_box/dao/dao.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';

/// Локальный источник данных для работы с заметками
abstract interface class NoteLocalDataSource {
  /// Получить все заметки, отсортированные по createdAt DESC
  Future<List<NoteObject>> getAll();

  /// Получить заметку по UID
  Future<NoteObject> getByUid(String uid);

  /// Получить заметки по UID папки
  Future<List<NoteObject>> getByFolderUid(String folderUid);

  /// Получить заметки без папки
  Future<List<NoteObject>> getWithoutFolder();

  /// Сохранить новую заметку
  Future<NoteObject> save(NoteObject note);

  /// Обновить существующую заметку
  Future<NoteObject> update(NoteObject note);

  /// Удалить заметку по UID
  Future<void> delete(String uid);

  /// Переместить заметку в другую папку атомарно (обновляет обе папки)
  Future<NoteObject> moveToFolder({
    required String noteUid,
    String? targetFolderUid,
  });

  /// Стрим всех заметок с реактивными обновлениями
  Stream<List<NoteObject>> watchAll();

  /// Стрим заметок по UID папки с реактивными обновлениями
  Stream<List<NoteObject>> watchByFolderUid(String folderUid);

  /// Стрим заметок без папки с реактивными обновлениями
  Stream<List<NoteObject>> watchWithoutFolder();

  /// Сохранить заметку с папкой и тегами атомарно
  Future<NoteObject> saveWithRelations({
    required NoteObject note,
    String? folderUid,
    List<String> tagNames,
  });
}

/// Реализация на основе ObjectBox
@Singleton(as: NoteLocalDataSource)
class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  final DatabaseClient _db;

  static const _noteDao = NoteDao();
  static const _folderDao = FolderDao();
  static const _tagDao = TagDao();

  NoteLocalDataSourceImpl(this._db);

  @override
  Future<List<NoteObject>> getAll() async => _noteDao.findAll(_db.box);

  @override
  Future<NoteObject> getByUid(String uid) async {
    return _noteDao
        .findByUid(_db.box, uid)
        .orThrowNotFound(EntityType.note, uid);
  }

  @override
  Future<List<NoteObject>> getByFolderUid(String folderUid) async {
    final folder = _folderDao
        .findByUid(_db.box, folderUid)
        .orThrowNotFound(EntityType.folder, folderUid);

    return _noteDao.findByFolderId(_db.box, folder.id);
  }

  @override
  Future<List<NoteObject>> getWithoutFolder() async {
    return _noteDao.findWithoutFolder(_db.box);
  }

  @override
  Future<NoteObject> save(NoteObject note) async {
    return _noteDao.put(_db.box, note, mode: PutMode.insert);
  }

  @override
  Future<NoteObject> update(NoteObject note) async {
    return _noteDao.put(_db.box, note, mode: PutMode.update);
  }

  @override
  Future<void> delete(String uid) async {
    await _db.runInTransactionAsync((Store store, String noteUid) {
      final box = store.box;
      final note = _noteDao.findByUid(box, noteUid);
      if (note == null) return;

      final folder = note.folder.target;
      _noteDao.remove(box, note.id);
      _folderDao.touch(box, folder);
    }, param: uid);
  }

  @override
  Future<NoteObject> moveToFolder({
    required String noteUid,
    String? targetFolderUid,
  }) async {
    return _db.runInTransactionAsync((
      Store store,
      ({String noteUid, String? folderUid}) params,
    ) {
      final box = store.box;

      final note = _noteDao.findByUid(box, params.noteUid);
      if (note == null) throw Exception('Note not found: ${params.noteUid}');

      final oldFolder = note.folder.target;
      final newFolder = params.folderUid != null
          ? _folderDao.findByUid(box, params.folderUid!)
          : null;

      note.folder.target = newFolder;
      note.updatedAt = DateTime.now();
      _noteDao.put(box, note, mode: PutMode.update);

      _folderDao
        ..touch(box, oldFolder)
        ..touch(box, newFolder);

      return note;
    }, param: (noteUid: noteUid, folderUid: targetFolderUid));
  }

  @override
  Stream<List<NoteObject>> watchAll() {
    return _noteDao
        .queryAll(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  @override
  Stream<List<NoteObject>> watchByFolderUid(String folderUid) {
    final folder = _folderDao
        .findByUid(_db.box, folderUid)
        .orThrowNotFound(EntityType.folder, folderUid);

    return _noteDao
        .queryByFolderId(_db.box, folder.id)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  @override
  Stream<List<NoteObject>> watchWithoutFolder() {
    return _noteDao
        .queryWithoutFolder(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  @override
  Future<NoteObject> saveWithRelations({
    required NoteObject note,
    String? folderUid,
    List<String> tagNames = const [],
  }) async {
    return _db.runInTransactionAsync((
      Store store,
      ({NoteObject note, String? folderUid, List<String> tags}) p,
    ) {
      final box = store.box;
      final noteToSave = p.note;

      final targetFolder = p.folderUid != null
          ? _folderDao.findByUid(box, p.folderUid!)
          : null;

      if (targetFolder != null) noteToSave.folder.target = targetFolder;

      if (p.tags.isNotEmpty) {
        final now = DateTime.now();
        final tags = [
          for (final name in p.tags)
            TagObject(name: name.toLowerCase().trim(), createdAt: now),
        ];
        _tagDao.putMany(box, tags);
        noteToSave.tags.addAll(tags);
      }

      _noteDao.put(box, noteToSave, mode: PutMode.insert);
      _folderDao.touch(box, targetFolder);

      return noteToSave;
    }, param: (note: note, folderUid: folderUid, tags: tagNames));
  }
}
