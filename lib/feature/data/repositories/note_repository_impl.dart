import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/uuid/uuid_manager.dart';
import 'package:voice_notes/feature/data/local/data_sources/folder_local_data_source.dart';
import 'package:voice_notes/feature/data/local/data_sources/note_local_data_source.dart';
import 'package:voice_notes/feature/data/local/mappers/note_mapper.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

/// Реализация репозитория для управления заметками
@Singleton(as: NoteRepository)
class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource _noteDataSource;
  final FolderLocalDataSource _folderDataSource;

  NoteRepositoryImpl(this._noteDataSource, this._folderDataSource);

  @override
  Future<List<NoteEntity>> getAll() async {
    final objects = await _noteDataSource.getAll();
    return NoteMapper.toDomainList(objects);
  }

  @override
  Future<NoteEntity?> getByUid(String uid) async {
    final obj = await _noteDataSource.getByUid(uid);
    if (obj == null) return null;

    return NoteMapper.toDomain(obj);
  }

  @override
  Future<List<NoteEntity>> getByFolderId(String folderId) async {
    final obj = await _folderDataSource.getByUid(folderId);
    if (obj == null) return [];

    final objects = await _noteDataSource.getByFolderId(obj.id);
    return NoteMapper.toDomainList(objects);
  }

  @override
  Future<List<NoteEntity>> getWithoutFolder() async {
    final objects = await _noteDataSource.getWithoutFolder();
    return NoteMapper.toDomainList(objects);
  }

  @override
  Future<NoteEntity> create({
    required String text,
    required Duration duration,
    required String modelName,
    required String language,
    required int wordCount,
    String? folderId,
    List<String> tagNames = const [],
    bool hasAudio = true,
  }) async {
    final now = DateTime.now();

    final noteObject = NoteObject(
      uid: UuidManager.v1(),
      text: text,
      createdAt: now,
      updatedAt: now,
      durationMs: duration.inMilliseconds,
      modelName: modelName,
      language: language,
      wordCount: wordCount,
      hasAudio: hasAudio,
    );

    final savedNote = await _noteDataSource.saveWithRelations(
      note: noteObject,
      folderUid: folderId,
      tagNames: tagNames,
    );

    return NoteMapper.toDomain(savedNote);
  }

  @override
  Future<NoteEntity> update(NoteEntity note) async {
    final existing = await _noteDataSource.getByUid(note.uuid);
    if (existing == null) throw Exception('Note not found: ${note.uuid}');

    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    NoteMapper.updateEntity(existing, updatedNote);

    final newObj = await _noteDataSource.update(existing);
    return NoteMapper.toDomain(newObj);
  }

  @override
  Future<void> delete(String uid) async {
    await _noteDataSource.delete(uid);
  }

  @override
  Future<void> moveToFolder(String noteUid, String? folderId) async {
    await _noteDataSource.moveToFolder(
      noteUid: noteUid,
      targetFolderUid: folderId,
    );
  }

  @override
  Stream<List<NoteEntity>> watchAll() {
    return _noteDataSource.watchAll().map(NoteMapper.toDomainList);
  }

  @override
  Stream<List<NoteEntity>> watchByFolderId(String folderUuid) {
    final folder = _folderDataSource.getByUidSync(folderUuid)!;

    return _noteDataSource
        .watchByFolderId(folder.id)
        .map(NoteMapper.toDomainList);
  }

  @override
  Stream<List<NoteEntity>> watchWithoutFolder() {
    return _noteDataSource.watchWithoutFolder().map(NoteMapper.toDomainList);
  }
}
