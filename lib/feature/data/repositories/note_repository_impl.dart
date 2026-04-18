import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/uuid/uuid_manager.dart';
import 'package:voice_notes/feature/data/local/data_sources/note_local_data_source.dart';
import 'package:voice_notes/feature/data/local/mappers/note_mapper.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

/// Реализация репозитория для управления заметками
@Singleton(as: NoteRepository)
class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource _noteDataSource;

  final StreamController<String> _deletedController =
      StreamController<String>.broadcast();

  NoteRepositoryImpl(this._noteDataSource);

  @override
  Stream<String> get onDeleted => _deletedController.stream;

  @override
  Future<List<NoteEntity>> getAll() async {
    final objects = await _noteDataSource.getAll();

    return NoteMapper.toDomainList(objects);
  }

  @override
  Future<NoteEntity> getByUid(String uid) async {
    final obj = await _noteDataSource.getByUid(uid);

    return NoteMapper.toDomain(obj);
  }

  @override
  Future<NoteEntity?> getByUidOrNull(String uid) async {
    final obj = await _noteDataSource.findByUidOrNull(uid);
    return obj == null ? null : NoteMapper.toDomain(obj);
  }

  @override
  Future<List<NoteEntity>> getByFolderId(String folderUid) async {
    final objects = await _noteDataSource.getByFolderUid(folderUid);

    return NoteMapper.toDomainList(objects);
  }

  @override
  Future<List<NoteEntity>> getWithoutFolder() async {
    final objects = await _noteDataSource.getWithoutFolder();
    return NoteMapper.toDomainList(objects);
  }

  @override
  Future<List<NoteEntity>> getQueued() async {
    final objects = await _noteDataSource.getQueued();
    return NoteMapper.toDomainList(objects);
  }

  @override
  Future<List<NoteEntity>> getFailed() async {
    final objects = await _noteDataSource.getFailed();
    return NoteMapper.toDomainList(objects);
  }

  @override
  Future<List<NoteEntity>> getCancelled() async {
    final objects = await _noteDataSource.getCancelled();
    return NoteMapper.toDomainList(objects);
  }

  @override
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
  }) async {
    final now = DateTime.now();

    final noteObject = NoteObject(
      uid: uid ?? UuidManager.v1(),
      text: text,
      createdAt: now,
      updatedAt: now,
      durationMs: duration.inMilliseconds,
      modelName: modelName,
      language: language,
      wordCount: wordCount,
      statusValue: TranscriptionStatus.completed.value,
    );

    final savedNote = await _noteDataSource.saveWithRelations(
      note: noteObject,
      folderUid: folderUid,
      tagNames: tagNames,
      audio: audio,
    );

    return NoteMapper.toDomain(savedNote);
  }

  @override
  Future<NoteEntity> createQueued({
    required String uid,
    required String folderUid,
    required Duration duration,
    required NoteAudioEntity audio,
  }) async {
    final now = DateTime.now();

    final noteObject = NoteObject(
      uid: uid,
      text: '',
      createdAt: now,
      updatedAt: now,
      durationMs: duration.inMilliseconds,
      modelName: '',
      language: '',
      wordCount: 0,
      statusValue: TranscriptionStatus.queued.value,
    );

    final savedNote = await _noteDataSource.saveWithRelations(
      note: noteObject,
      folderUid: folderUid,
      audio: audio,
    );

    return NoteMapper.toDomain(savedNote);
  }

  @override
  Future<NoteEntity> update(NoteEntity note) async {
    final noteObject = NoteMapper.toEntity(note);
    final tagNames = note.tags.map((t) => t.name).toList();

    final newObj = await _noteDataSource.updateWithTags(
      note: noteObject,
      tagNames: tagNames,
    );
    return NoteMapper.toDomain(newObj);
  }

  @override
  Future<void> delete(String uid) async {
    // Эмитим uid ДО фактического delete, чтобы подписчики (очередь
    // транскрибации) успели добавить uid в cancelled set и корректно
    // отбросить in-flight результат ASR.
    _deletedController.add(uid);

    // DataSource транзакционно удаляет NoteObject + NoteAudioObject и
    // возвращает относительный путь файла (или null, если аудио не было).
    final audioRelativePath = await _noteDataSource.delete(uid);

    // Удаление файла — вне транзакции, best-effort. deleteFile не throw'ит,
    // поэтому БД остаётся консистентной даже если файл уже удалён извне.
    if (audioRelativePath != null) {
      await AudioPaths.deleteFile(audioRelativePath);
    }
  }

  @override
  Future<NoteEntity?> markTranscribing(String uid) async {
    final obj = await _noteDataSource.updateStatus(
      uid: uid,
      statusValue: TranscriptionStatus.transcribing.value,
    );

    return obj == null ? null : NoteMapper.toDomain(obj);
  }

  @override
  Future<NoteEntity?> markQueued(String uid) async {
    final obj = await _noteDataSource.updateStatus(
      uid: uid,
      statusValue: TranscriptionStatus.queued.value,
      resetFailureReason: true,
    );

    return obj == null ? null : NoteMapper.toDomain(obj);
  }

  @override
  Future<NoteEntity?> completeTranscription({
    required String uid,
    required String text,
    required String language,
    required String modelName,
    required int wordCount,
    required bool deleteAudio,
  }) async {
    final result = await _noteDataSource.completeTranscription(
      uid: uid,
      text: text,
      language: language,
      modelName: modelName,
      wordCount: wordCount,
      clearAudio: deleteAudio,
    );

    final note = result.note;
    if (note == null) return null;

    final relativePath = result.audioRelativePath;
    if (relativePath != null) await AudioPaths.deleteFile(relativePath);

    return NoteMapper.toDomain(note);
  }

  @override
  Future<NoteEntity?> failTranscription({
    required String uid,
    required TranscriptionFailureReason reason,
  }) async {
    final obj = await _noteDataSource.updateStatus(
      uid: uid,
      statusValue: TranscriptionStatus.failed.value,
      failureReasonValue: reason.value,
    );
    return obj == null ? null : NoteMapper.toDomain(obj);
  }

  @override
  Future<NoteEntity?> markCancelled(String uid) async {
    final obj = await _noteDataSource.updateStatus(
      uid: uid,
      statusValue: TranscriptionStatus.cancelled.value,
      resetFailureReason: true,
    );
    return obj == null ? null : NoteMapper.toDomain(obj);
  }

  @override
  Future<void> resetTranscribingToQueued() async {
    return _noteDataSource.resetTranscribingToQueued();
  }

  @override
  Future<void> moveToFolder(String noteUid, String? folderUid) async {
    await _noteDataSource.moveToFolder(
      noteUid: noteUid,
      targetFolderUid: folderUid,
    );
  }

  @override
  Stream<List<NoteEntity>> watchAll() {
    return _noteDataSource.watchAll().map(NoteMapper.toDomainList);
  }

  @override
  Stream<List<NoteEntity>> watchByFolderId(String folderUid) {
    return _noteDataSource
        .watchByFolderUid(folderUid)
        .map(NoteMapper.toDomainList);
  }

  @override
  Stream<List<NoteEntity>> watchWithoutFolder() {
    return _noteDataSource.watchWithoutFolder().map(NoteMapper.toDomainList);
  }

  @override
  Stream<List<NoteEntity>> watchQueued() {
    return _noteDataSource.watchQueued().map(NoteMapper.toDomainList);
  }

  @override
  Stream<List<NoteEntity>> watchFailed() {
    return _noteDataSource.watchFailed().map(NoteMapper.toDomainList);
  }

  @override
  Stream<List<NoteEntity>> watchCancelled() {
    return _noteDataSource.watchCancelled().map(NoteMapper.toDomainList);
  }

  @override
  Stream<List<NoteEntity>> watchTranscribing() {
    return _noteDataSource.watchTranscribing().map(NoteMapper.toDomainList);
  }

  @override
  @disposeMethod
  Future<void> dispose() async {
    await _deletedController.close();
  }
}
