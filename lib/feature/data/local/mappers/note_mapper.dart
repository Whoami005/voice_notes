import 'package:voice_notes/feature/data/local/mappers/tag_mapper.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';

abstract final class NoteMapper {
  static NoteEntity toDomain(NoteObject e, {List<TagEntity>? tags}) {
    return NoteEntity(
      id: e.uid,
      folderId: e.folder.targetId != 0 ? e.folder.targetId.toString() : null,
      text: e.text,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      duration: Duration(milliseconds: e.durationMs),
      modelName: e.modelName,
      language: e.language,
      wordCount: e.wordCount,
      tags: tags ?? TagMapper.toDomainList(e.tags.toList()),
      hasAudio: e.hasAudio,
    );
  }

  static NoteObject toEntity(NoteEntity n, {int id = 0}) {
    return NoteObject(
      id: id,
      uid: n.id,
      text: n.text,
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
      durationMs: n.duration.inMilliseconds,
      modelName: n.modelName,
      language: n.language,
      wordCount: n.wordCount,
      hasAudio: n.hasAudio,
    );
  }

  /// Обновляет существующую entity значениями из domain модели.
  static void updateEntity(NoteObject entity, NoteEntity note) {
    entity.text = note.text;
    entity.updatedAt = note.updatedAt;
    entity.durationMs = note.duration.inMilliseconds;
    entity.modelName = note.modelName;
    entity.language = note.language;
    entity.wordCount = note.wordCount;
    entity.hasAudio = note.hasAudio;
  }

  static List<NoteEntity> toDomainList(List<NoteObject> entities) {
    return [for (final e in entities) toDomain(e)];
  }
}
