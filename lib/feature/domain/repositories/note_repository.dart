import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';

abstract interface class NoteRepository {
  Future<List<NoteEntity>> getAll();

  Future<NoteEntity> getByUid(String uid);

  Future<NoteEntity?> getByUidOrNull(String uid);

  Future<List<NoteEntity>> getByFolderId(String folderUid);

  Future<List<NoteEntity>> getWithoutFolder();

  /// Только queued, createdAt ASC.
  Future<List<NoteEntity>> getQueued();

  /// Заметки в статусе `failed`, updatedAt DESC.
  Future<List<NoteEntity>> getFailed();

  /// Заметки в статусе `cancelled`, updatedAt DESC.
  Future<List<NoteEntity>> getCancelled();

  Future<NoteEntity> create({
    required String text,
    required Duration duration,
    required String modelName,
    required String language,
    required int wordCount,
    String? uid,
    String? folderUid,
    List<String> tagNames = const [],
    NoteAudioEntity? audio,
  });

  /// Создаёт заметку сразу в статусе queued: после остановки записи она
  /// видна в списке, очередь транскрибации довыполнит её в фоне.
  Future<NoteEntity> createQueued({
    required String uid,
    required String folderUid,
    required Duration duration,
    required NoteAudioEntity audio,
  });

  Future<NoteEntity> update(NoteEntity note);

  Future<void> delete(String uid);

  Future<NoteEntity?> markTranscribing(String uid);

  /// Обнуляет `failureReason` (для retry failed → queued).
  Future<NoteEntity?> markQueued(String uid);

  /// Статус → completed. Если [deleteAudio] — удаляет аудио-relation и файл.
  Future<NoteEntity?> completeTranscription({
    required String uid,
    required String text,
    required String language,
    required String modelName,
    required int wordCount,
    required bool deleteAudio,
  });

  Future<NoteEntity?> failTranscription({
    required String uid,
    required TranscriptionFailureReason reason,
  });

  Future<NoteEntity?> markCancelled(String uid);

  /// Cold-start recovery: восстановление после kill'а изолята.
  Future<void> resetTranscribingToQueued();

  Future<void> moveToFolder(String noteUid, String? folderUid);

  Stream<List<NoteEntity>> watchAll();

  Stream<List<NoteEntity>> watchByFolderId(String folderUid);

  Stream<List<NoteEntity>> watchWithoutFolder();

  Stream<List<NoteEntity>> watchQueued();

  Stream<List<NoteEntity>> watchFailed();

  Stream<List<NoteEntity>> watchCancelled();

  /// Заметки в статусе `transcribing`. 0 или 1 элемент. Нужен
  /// `QueueManagementCubit`, чтобы тайл «Сейчас обрабатывается» реактивно
  /// обновлялся при изменениях сущности (title, folder).
  Stream<List<NoteEntity>> watchTranscribing();

  /// Эмит ДО фактического удаления — даёт подписчикам (очередь
  /// транскрибации) шанс отменить in-flight операции.
  Stream<String> get onDeleted;

  Future<void> dispose();
}
