import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/error/app_exception.dart';
import 'package:voice_notes/core/packages/db/object_box/dao/dao.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/mappers/note_audio_mapper.dart';
import 'package:voice_notes/feature/data/local/mappers/note_transcription_segment_mapper.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/data/local/models/note_transcription_segment_object.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_meta_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_segment_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';

abstract interface class NoteLocalDataSource {
  Future<List<NoteObject>> getAll();

  Future<NoteObject> getByUid(String uid);

  Future<NoteObject?> findByUidOrNull(String uid);

  Future<List<NoteObject>> getByFolderUid(String folderUid);

  Future<List<NoteObject>> getWithoutFolder();

  Future<NoteObject> save(NoteObject note);

  Future<NoteObject> update(NoteObject note);

  /// Возвращает относительный путь аудио (или null) — файл удаляется
  /// вне транзакции, чтобы БД оставалась консистентной при ошибке I/O.
  Future<String?> delete(String uid);

  Future<NoteObject> moveToFolder({
    required String noteUid,
    String? targetFolderUid,
  });

  Stream<List<NoteObject>> watchAll();

  Stream<List<NoteObject>> watchByFolderUid(String folderUid);

  Stream<List<NoteObject>> watchWithoutFolder();

  Future<NoteObject> saveWithRelations({
    required NoteObject note,
    String? folderUid,
    List<String> tagNames,
    NoteAudioEntity? audio,
  });

  Future<NoteObject> updateWithTags({
    required NoteObject note,
    required List<String> tagNames,
  });

  /// Только queued, createdAt ASC.
  Future<List<NoteObject>> getQueued();

  Stream<List<NoteObject>> watchQueued();

  /// Заметки в статусе `failed`. Свежие — первыми (updatedAt DESC).
  Future<List<NoteObject>> getFailed();

  Stream<List<NoteObject>> watchFailed();

  /// Заметки в статусе `cancelled`. Свежие — первыми (updatedAt DESC).
  Future<List<NoteObject>> getCancelled();

  Stream<List<NoteObject>> watchCancelled();

  /// Заметки в статусе `transcribing`. 0 или 1 элемент (инвариант сервиса).
  /// Нужен для реактивного тайла «Сейчас обрабатывается» на экране очереди.
  Future<List<NoteObject>> getTranscribing();

  Stream<List<NoteObject>> watchTranscribing();

  /// Cold-start recovery: подбирает заметки, застрявшие в transcribing
  /// после kill'а изолята.
  Future<void> resetTranscribingToQueued();

  /// [resetFailureReason] = true — зануляет причину прошлого провала
  /// (failed → queued/cancelled).
  Future<NoteObject?> updateStatus({
    required String uid,
    required int statusValue,
    int? failureReasonValue,
    bool resetFailureReason = false,
  });

  /// Возвращает `audioRelativePath` (или null) для внетранзакционного
  /// удаления файла. Если `clearAudio` — relation обнуляется и audio
  /// object удаляется в той же транзакции.
  Future<({NoteObject? note, String? audioRelativePath})>
  completeTranscription({
    required String uid,
    required String text,
    required NoteTranscriptionMetaEntity transcription,
    required List<NoteTranscriptionSegmentEntity> transcriptionSegments,
    required bool clearAudio,
  });
}

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
  Future<NoteObject?> findByUidOrNull(String uid) async {
    return _noteDao.findByUid(_db.box, uid);
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
      final segmentIds = [
        for (final segment in note.transcriptionSegments.toList()) segment.id,
      ];

      final folder = note.folder.target;
      _noteDao.remove(box, note.id);
      if (audio != null) {
        // ObjectBox не каскадит delete через ToOne — удаляем руками.
        box<NoteAudioObject>().remove(audio.id);
      }
      if (segmentIds.isNotEmpty) {
        box<NoteTranscriptionSegmentObject>().removeMany(segmentIds);
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
        final tags = _tagDao.getOrCreateMany(box, p.tags);
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

  @override
  Future<List<NoteObject>> getQueued() async {
    return _noteDao.findQueued(_db.box);
  }

  @override
  Stream<List<NoteObject>> watchQueued() {
    return _noteDao
        .queryQueued(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  @override
  Future<List<NoteObject>> getFailed() async {
    return _noteDao.findFailed(_db.box);
  }

  @override
  Stream<List<NoteObject>> watchFailed() {
    return _noteDao
        .queryFailed(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  @override
  Future<List<NoteObject>> getCancelled() async {
    return _noteDao.findCancelled(_db.box);
  }

  @override
  Stream<List<NoteObject>> watchCancelled() {
    return _noteDao
        .queryCancelled(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  @override
  Future<List<NoteObject>> getTranscribing() async {
    return _noteDao.findTranscribing(_db.box);
  }

  @override
  Stream<List<NoteObject>> watchTranscribing() {
    return _noteDao
        .queryTranscribing(_db.box)
        .watch(triggerImmediately: true)
        .map((q) => q.find());
  }

  @override
  Future<void> resetTranscribingToQueued() async {
    await _db.runInTransactionAsync<void, Object?>((Store store, _) {
      _noteDao.resetTranscribingToQueued(store.box);
    }, param: null);
  }

  @override
  Future<NoteObject?> updateStatus({
    required String uid,
    required int statusValue,
    int? failureReasonValue,
    bool resetFailureReason = false,
  }) async {
    return _db.runInTransactionAsync(
      (
        Store store,
        ({
          String uid,
          int statusValue,
          int? failureReasonValue,
          bool resetFailureReason,
        })
        p,
      ) {
        final box = store.box;
        final note = _noteDao.findByUid(box, p.uid);
        if (note == null) return null;

        note.statusValue = p.statusValue;
        if (p.resetFailureReason) {
          note.failureReasonValue = null;
        } else if (p.failureReasonValue != null) {
          note.failureReasonValue = p.failureReasonValue;
        }
        note.updatedAt = DateTime.now();

        _noteDao.put(box, note, mode: PutMode.update);
        return note;
      },
      param: (
        uid: uid,
        statusValue: statusValue,
        failureReasonValue: failureReasonValue,
        resetFailureReason: resetFailureReason,
      ),
    );
  }

  @override
  Future<({NoteObject? note, String? audioRelativePath})>
  completeTranscription({
    required String uid,
    required String text,
    required NoteTranscriptionMetaEntity transcription,
    required List<NoteTranscriptionSegmentEntity> transcriptionSegments,
    required bool clearAudio,
  }) async {
    return _db.runInTransactionAsync(
      (
        Store store,
        ({
          String uid,
          String text,
          NoteTranscriptionMetaEntity transcription,
          List<NoteTranscriptionSegmentEntity> transcriptionSegments,
          bool clearAudio,
        })
        p,
      ) {
        final box = store.box;
        final note = _noteDao.findByUid(box, p.uid);
        if (note == null) return (note: null, audioRelativePath: null);

        note
          ..text = p.text
          ..transcriptionModelId = p.transcription.modelId.value
          ..transcriptionLanguageCode = p.transcription.languageCode
          ..transcriptionTaskTypeValue = p.transcription.taskType.value
          ..transcribedAt = p.transcription.transcribedAt
          ..transcriptionProcessingTimeMs =
              p.transcription.processingTime.inMilliseconds
          ..transcriptionStrategyValue = p.transcription.strategyUsed.value
          ..transcriptionUsedVad = p.transcription.usedVad
          ..transcriptionFellBackFromVad = p.transcription.fellBackFromVad
          ..transcriptionEmotionLabel = p.transcription.emotionLabel
          ..transcriptionEventLabel = p.transcription.eventLabel
          ..transcriptionUsedItn = p.transcription.usedItn
          ..transcriptionUsedPunctuation = p.transcription.usedPunctuation
          ..statusValue = TranscriptionStatus.completed.value
          ..failureReasonValue = null
          ..updatedAt = DateTime.now();

        final segmentBox = box<NoteTranscriptionSegmentObject>();
        final previousSegmentIds = [
          for (final segment in note.transcriptionSegments.toList()) segment.id,
        ];
        if (previousSegmentIds.isNotEmpty) {
          segmentBox.removeMany(previousSegmentIds);
        }

        String? audioRelativePath;
        int? removedAudioId;
        if (p.clearAudio) {
          final audio = note.audio.target;
          if (audio != null) {
            audioRelativePath = audio.relativePath;
            removedAudioId = audio.id;
            note.audio.target = null;
          }
        }

        _noteDao.put(box, note, mode: PutMode.update);
        if (p.transcriptionSegments.isNotEmpty) {
          final segmentObjects = [
            for (final segment in p.transcriptionSegments)
              NoteTranscriptionSegmentMapper.toEntity(
                entity: segment,
                note: note,
              ),
          ];
          segmentBox.putMany(segmentObjects);
        }
        if (removedAudioId != null) {
          box<NoteAudioObject>().remove(removedAudioId);
        }

        return (note: note, audioRelativePath: audioRelativePath);
      },
      param: (
        uid: uid,
        text: text,
        transcription: transcription,
        transcriptionSegments: transcriptionSegments,
        clearAudio: clearAudio,
      ),
    );
  }
}
