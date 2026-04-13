import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/error/app_exception.dart';
import 'package:voice_notes/core/packages/db/object_box/dao/dao.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/mappers/note_audio_mapper.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';

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

  /// Удалить заметку по UID.
  ///
  /// Если у заметки было аудио — удаляет и связанный [NoteAudioObject]
  /// в той же транзакции. Возвращает относительный путь аудиофайла
  /// (для последующего удаления с диска вне транзакции) или null, если
  /// аудио не было.
  Future<String?> delete(String uid);

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

  /// Сохранить заметку с папкой, тегами и (опционально) аудио атомарно.
  ///
  /// Если передан [audio] — внутри транзакции создаётся `NoteAudioObject`
  /// с денормализованным `folderUid` и прикрепляется к заметке через relation.
  Future<NoteObject> saveWithRelations({
    required NoteObject note,
    String? folderUid,
    List<String> tagNames,
    NoteAudioEntity? audio,
  });

  /// Обновить заметку с тегами атомарно
  Future<NoteObject> updateWithTags({
    required NoteObject note,
    required List<String> tagNames,
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
  Future<String?> delete(String uid) async {
    return _db.runInTransactionAsync((Store store, String noteUid) {
      final box = store.box;
      final note = _noteDao.findByUid(box, noteUid);
      if (note == null) return null;

      // Захватываем аудио ДО удаления заметки, чтобы знать путь к файлу
      // для последующей очистки и id для remove.
      final audio = note.audio.target;
      final audioRelativePath = audio?.relativePath;

      final folder = note.folder.target;
      _noteDao.remove(box, note.id);
      if (audio != null) {
        // ObjectBox не каскадит delete через ToOne — удаляем руками.
        box<NoteAudioObject>().remove(audio.id);
      }
      _folderDao.touch(box, folder);

      return audioRelativePath;
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

      // Синхронизируем денормализованный folderUid в audio relation —
      // иначе Storage screen будет показывать аудио в старой папке.
      final audio = note.audio.target;
      if (audio != null) {
        audio.folderUid = params.folderUid;
      }

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
    NoteAudioEntity? audio,
  }) async {
    return _db.runInTransactionAsync((
      Store store,
      ({
        NoteObject note,
        String? folderUid,
        List<String> tags,
        NoteAudioEntity? audio,
      })
      p,
    ) {
      final box = store.box;
      final note = p.note;

      final targetFolder = p.folderUid != null
          ? _folderDao.findByUid(box, p.folderUid!)
          : null;

      if (targetFolder != null) note.folder.target = targetFolder;

      if (p.tags.isNotEmpty) {
        final now = DateTime.now();
        final tags = [
          for (final name in p.tags)
            TagObject(name: name.toLowerCase().trim(), createdAt: now),
        ];
        _tagDao.putMany(box, tags);
        note.tags.addAll(tags);
      }

      // Аудио-relation: создаём NoteAudioObject с денормализованным folderUid
      // и прицепляем к заметке. ObjectBox сохранит его каскадом при put(note).
      if (p.audio != null) {
        note.audio.target = NoteAudioMapper.toEntity(
          entity: p.audio!,
          folderUid: p.folderUid,
        );
      }

      _noteDao.put(box, note, mode: PutMode.insert);
      _folderDao.touch(box, targetFolder);

      return note;
    }, param: (note: note, folderUid: folderUid, tags: tagNames, audio: audio));
  }

  @override
  Future<NoteObject> updateWithTags({
    required NoteObject note,
    required List<String> tagNames,
  }) async {
    return _db.runInTransactionAsync((
      Store store,
      ({NoteObject note, List<String> tagNames}) p,
    ) {
      final box = store.box;

      final existing = _noteDao
          .findByUid(box, p.note.uid)
          .orThrowNotFound(EntityType.note, p.note.uid);

      p.note.id = existing.id;
      p.note.folder.target = existing.folder.target;
      p.note.audio.target = existing.audio.target;

      p.note.tags.clear();
      if (p.tagNames.isNotEmpty) {
        final tags = _tagDao.getOrCreateMany(box, p.tagNames);
        p.note.tags.addAll(tags);
      }

      _noteDao.put(box, p.note, mode: PutMode.update);
      return p.note;
    }, param: (note: note, tagNames: tagNames));
  }
}
