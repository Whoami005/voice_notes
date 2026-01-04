import 'package:injectable/injectable.dart' hide Order;
import 'package:objectbox/objectbox.dart' show Order, PutMode;
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart'
    hide Order;
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';

/// Локальный источник данных для работы с заметками
abstract interface class NoteLocalDataSource {
  /// Получить все заметки, отсортированные по createdAt DESC
  Future<List<NoteObject>> getAll();

  /// Получить заметку по UID
  Future<NoteObject?> getByUid(String uid);

  /// Получить заметки по ID папки
  Future<List<NoteObject>> getByFolderId(int folderId);

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

  /// Стрим заметок по ID папки с реактивными обновлениями
  Stream<List<NoteObject>> watchByFolderId(int folderId);

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

  Box<NoteObject> get _noteBox => _db.box<NoteObject>();

  NoteLocalDataSourceImpl(this._db);

  @override
  Future<List<NoteObject>> getAll() async {
    final query = _noteBox
        .query()
        .order(NoteObject_.createdAt, flags: Order.descending)
        .build();
    final result = query.find();
    query.close();

    return result;
  }

  @override
  Future<NoteObject?> getByUid(String uid) async {
    final query = _noteBox.query(NoteObject_.uid.equals(uid)).build();
    final result = query.findFirst();
    query.close();

    return result;
  }

  @override
  Future<List<NoteObject>> getByFolderId(int folderId) async {
    final query = _noteBox
        .query(NoteObject_.folder.equals(folderId))
        .order(NoteObject_.createdAt, flags: Order.descending)
        .build();
    final result = query.find();
    query.close();

    return result;
  }

  @override
  Future<List<NoteObject>> getWithoutFolder() async {
    final query = _noteBox
        .query(NoteObject_.folder.isNull())
        .order(NoteObject_.createdAt, flags: Order.descending)
        .build();
    final result = query.find();
    query.close();

    return result;
  }

  @override
  Future<NoteObject> save(NoteObject note) async {
    return _noteBox.putAndGetAsync(note, mode: PutMode.insert);
  }

  @override
  Future<NoteObject> update(NoteObject note) async {
    return _noteBox.putAndGetAsync(note, mode: PutMode.update);
  }

  @override
  Future<void> delete(String uid) async {
    await _db.runInTransactionAsync((Store store, String noteUid) async {
      final noteBox = store.box<NoteObject>();
      final folderBox = store.box<FolderObject>();

      final query = noteBox.query(NoteObject_.uid.equals(noteUid)).build();
      final note = query.findFirst();
      query.close();

      if (note == null) return;

      final folder = note.folder.target;
      noteBox.remove(note.id);

      // Обновить updatedAt папки для триггера watch()
      if (folder != null) {
        folder.updatedAt = DateTime.now();
        folderBox.put(folder, mode: PutMode.update);
      }
    }, param: uid);
  }

  @override
  Future<NoteObject> moveToFolder({
    required String noteUid,
    String? targetFolderUid,
  }) async {
    return _db.runInTransactionAsync(
      (Store store, _MoveFolderParams params) {
        final noteBox = store.box<NoteObject>();
        final folderBox = store.box<FolderObject>();

        final noteQuery = noteBox
            .query(NoteObject_.uid.equals(params.noteUid))
            .build();
        final note = noteQuery.findFirst();
        noteQuery.close();

        if (note == null) {
          throw Exception('Note not found: ${params.noteUid}');
        }

        final oldFolder = note.folder.target;
        FolderObject? newFolder;

        if (params.targetFolderUid != null) {
          final folderQuery = folderBox
              .query(FolderObject_.uid.equals(params.targetFolderUid!))
              .build();
          newFolder = folderQuery.findFirst();
          folderQuery.close();
        }

        note.folder.target = newFolder;
        note.updatedAt = DateTime.now();
        noteBox.put(note, mode: PutMode.update);

        final now = DateTime.now();

        // Обновить старую папку (откуда забрали заметку)
        if (oldFolder != null) {
          oldFolder.updatedAt = now;
          folderBox.put(oldFolder, mode: PutMode.update);
        }

        // Обновить новую папку (куда переместили заметку)
        if (newFolder != null) {
          newFolder.updatedAt = now;
          folderBox.put(newFolder, mode: PutMode.update);
        }

        return note;
      },
      param: _MoveFolderParams(
        noteUid: noteUid,
        targetFolderUid: targetFolderUid,
      ),
    );
  }

  @override
  Stream<List<NoteObject>> watchAll() {
    return _noteBox
        .query()
        .order(NoteObject_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }

  @override
  Stream<List<NoteObject>> watchByFolderId(int folderId) {
    return _noteBox
        .query(NoteObject_.folder.equals(folderId))
        .order(NoteObject_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }

  @override
  Stream<List<NoteObject>> watchWithoutFolder() {
    return _noteBox
        .query(NoteObject_.folder.isNull())
        .order(NoteObject_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((query) => query.find());
  }

  @override
  Future<NoteObject> saveWithRelations({
    required NoteObject note,
    String? folderUid,
    List<String> tagNames = const [],
  }) async {
    /// TODO: Отрефакторить
    return _db.runInTransactionAsync(
      (Store store, _SaveNoteParams params) {
        final noteBox = store.box<NoteObject>();
        final folderBox = store.box<FolderObject>();
        final tagBox = store.box<TagObject>();

        final note = params.note;
        FolderObject? targetFolder;

        if (params.folderUid != null) {
          final query = folderBox
              .query(FolderObject_.uid.equals(params.folderUid!))
              .build();
          final folder = query.findFirst();
          query.close();

          if (folder != null) {
            note.folder.target = folder;
            targetFolder = folder;
          }
        }

        if (params.tagNames.isNotEmpty) {
          final now = DateTime.now();
          final tags = [
            for (final name in params.tagNames)
              TagObject(name: name.toLowerCase().trim(), createdAt: now),
          ];
          tagBox.putMany(tags, mode: PutMode.put);
          note.tags.addAll(tags);
        }

        noteBox.put(note, mode: PutMode.insert);

        // Обновить updatedAt папки для триггера watch()
        if (targetFolder != null) {
          targetFolder.updatedAt = DateTime.now();
          folderBox.put(targetFolder, mode: PutMode.update);
        }

        return note;
      },
      param: _SaveNoteParams(
        note: note,
        folderUid: folderUid,
        tagNames: tagNames,
      ),
    );
  }
}

class _SaveNoteParams {
  final NoteObject note;
  final String? folderUid;
  final List<String> tagNames;

  _SaveNoteParams({
    required this.note,
    this.folderUid,
    this.tagNames = const [],
  });
}

class _MoveFolderParams {
  final String noteUid;
  final String? targetFolderUid;

  _MoveFolderParams({required this.noteUid, this.targetFolderUid});
}
