import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/db/object_box/dao/dao.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';

/// Локальный источник данных для работы с аудиозаписями заметок.
///
/// Отвечает за агрегационные запросы и удаление аудио (отвязка от заметки +
/// удаление `NoteAudioObject`). Заметка и её транскрипт сохраняются.
abstract interface class NoteAudioLocalDataSource {
  /// Получить все аудио
  Future<List<NoteAudioObject>> getAll();

  /// Получить пары (аудио, заметка-владелец) для указанной папки.
  ///
  /// Null — заметки без папки. Результат отсортирован по sizeBytes DESC.
  Future<List<(NoteAudioObject, NoteObject)>> getFolderNotePairs(
    String? folderUid,
  );

  /// Удалить аудио конкретной заметки.
  ///
  /// Возвращает относительный путь удалённого файла для последующего
  /// удаления с диска (вне транзакции) или null, если аудио не было.
  Future<String?> deleteNoteAudio(String noteUid);

  /// Удалить аудио всех заметок в указанной папке (null — без папки).
  ///
  /// Возвращает относительные пути удалённых файлов.
  Future<List<String>> deleteFolderAudio(String? folderUid);

  /// Удалить аудио всех заметок в приложении.
  ///
  /// Возвращает относительные пути удалённых файлов.
  Future<List<String>> deleteAllAudio();

  /// Реактивный стрим всех аудио
  Stream<List<NoteAudioObject>> watchAll();
}

/// Реализация на основе ObjectBox
@Singleton(as: NoteAudioLocalDataSource)
class NoteAudioLocalDataSourceImpl implements NoteAudioLocalDataSource {
  final DatabaseClient _db;

  static const _audioDao = NoteAudioDao();
  static const _noteDao = NoteDao();

  NoteAudioLocalDataSourceImpl(this._db);

  @override
  Future<List<NoteAudioObject>> getAll() async => _audioDao.findAll(_db.box);

  @override
  Future<List<(NoteAudioObject, NoteObject)>> getFolderNotePairs(
    String? folderUid,
  ) async {
    final audios = folderUid != null
        ? _audioDao.findByFolderUid(_db.box, folderUid)
        : _audioDao.findWithoutFolder(_db.box);

    if (audios.isEmpty) return const [];

    final audioIds = [for (final a in audios) a.id];
    final notes = _audioDao.findOwnerNotes(_db.box, audioIds);
    final noteByAudioId = <int, NoteObject>{
      for (final n in notes) n.audio.targetId: n,
    };

    // Пропускаем orphan-записи (NoteAudioObject без NoteObject-владельца).
    // Это возможно при нарушении целостности данных.
    return [
      for (final audio in audios)
        if (noteByAudioId[audio.id] case final note?) (audio, note),
    ];
  }

  @override
  Future<String?> deleteNoteAudio(String noteUid) async {
    return _db.runInTransactionAsync((Store store, String uid) {
      final box = store.box;

      final note = _noteDao.findByUid(box, uid);
      if (note == null) return null;

      final audio = note.audio.target;
      if (audio == null) return null;

      final path = audio.relativePath;
      note.audio.target = null;
      _noteDao.put(box, note, mode: PutMode.update);
      _audioDao.removeMany(box, [audio.id]);

      return path;
    }, param: noteUid);
  }

  @override
  Future<List<String>> deleteFolderAudio(String? folderUid) async {
    return _db.runInTransactionAsync((Store store, String? uid) {
      final box = store.box;

      final audios = uid != null
          ? _audioDao.findByFolderUid(box, uid)
          : _audioDao.findWithoutFolder(box);

      if (audios.isEmpty) return const <String>[];

      final audioIds = [for (final a in audios) a.id];
      final paths = [for (final a in audios) a.relativePath];

      final notes = _audioDao.findOwnerNotes(box, audioIds);
      for (final note in notes) {
        note.audio.target = null;
        _noteDao.put(box, note, mode: PutMode.update);
      }

      _audioDao.removeMany(box, audioIds);
      return paths;
    }, param: folderUid);
  }

  @override
  Future<List<String>> deleteAllAudio() async {
    return _db.runInTransactionAsync<List<String>, Object?>((
      Store store,
      Object? _,
    ) {
      final box = store.box;

      final audios = _audioDao.findAll(box);
      if (audios.isEmpty) return const <String>[];

      final paths = [for (final a in audios) a.relativePath];
      final audioIds = [for (final a in audios) a.id];

      final notes = _audioDao.findOwnerNotes(box, audioIds);
      for (final note in notes) {
        note.audio.target = null;
        _noteDao.put(box, note, mode: PutMode.update);
      }

      _audioDao.removeAll(box);
      return paths;
    }, param: null);
  }

  @override
  Stream<List<NoteAudioObject>> watchAll() {
    return _audioDao
        .queryAll(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }
}
