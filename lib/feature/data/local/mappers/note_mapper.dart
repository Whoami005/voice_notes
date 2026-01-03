import 'package:voice_notes/feature/data/local/mappers/tag_mapper.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';

abstract final class NoteMapper {
  static NoteEntity toDomain(NoteObject e) {
    return NoteEntity(
      uuid: e.uid,
      folderId: e.folder.targetId != 0 ? e.folder.targetId.toString() : null,
      text: e.text,
      duration: Duration(milliseconds: e.durationMs),
      modelName: e.modelName,
      language: e.language,
      wordCount: e.wordCount,
      tags: TagMapper.toDomainList(e.tags.toList()),
      hasAudio: e.hasAudio,
      createdAt: e.createdAt.toLocal(),
      updatedAt: e.updatedAt.toLocal(),
    );
  }

  static NoteObject toEntity(NoteEntity n, {int id = 0}) {
    return NoteObject(
      id: id,
      uid: n.uuid,
      text: n.text,
      durationMs: n.duration.inMilliseconds,
      modelName: n.modelName,
      language: n.language,
      wordCount: n.wordCount,
      hasAudio: n.hasAudio,
      createdAt: n.createdAt.toLocal(),
      updatedAt: n.updatedAt.toLocal(),
    );
  }

  /// Обновляет существующую entity значениями из domain модели.
  static void updateEntity(NoteObject entity, NoteEntity note) {
    entity
      ..text = note.text
      ..updatedAt = note.updatedAt
      ..durationMs = note.duration.inMilliseconds
      ..modelName = note.modelName
      ..language = note.language
      ..wordCount = note.wordCount
      ..hasAudio = note.hasAudio;
  }

  static List<NoteEntity> toDomainList(List<NoteObject> entities) {
    return [for (final e in entities) toDomain(e)];
  }
}
