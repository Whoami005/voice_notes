import 'package:voice_notes/feature/data/local/mappers/note_audio_mapper.dart';
import 'package:voice_notes/feature/data/local/mappers/tag_mapper.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';

abstract final class NoteMapper {
  static NoteEntity toDomain(NoteObject e) {
    final audioObj = e.audio.target;

    return NoteEntity(
      uuid: e.uid,
      folderId: e.folder.target?.uid,
      text: e.text,
      duration: Duration(milliseconds: e.durationMs),
      modelName: e.modelName,
      language: e.language,
      wordCount: e.wordCount,
      tags: TagMapper.toDomainList(e.tags.toList()),
      audio: audioObj != null ? NoteAudioMapper.toDomain(audioObj) : null,
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
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
    );
    // NB: audio relation НЕ устанавливается здесь — это будет делать
    // NoteLocalDataSource.saveWithRelations в Этапе 2, когда появится
    // фактический flow создания записи с сохранённым аудио.
  }

  /// Обновляет существующую entity значениями из domain-модели.
  ///
  /// **Не трогает audio relation** — это делается в
  /// `NoteLocalDataSourceImpl.updateWithTags` внутри транзакции, чтобы
  /// безопасно удалять `NoteAudioObject` при clear audio (без orphan).
  static void updateEntity(NoteObject entity, NoteEntity note) {
    entity
      ..text = note.text
      ..updatedAt = note.updatedAt
      ..durationMs = note.duration.inMilliseconds
      ..modelName = note.modelName
      ..language = note.language
      ..wordCount = note.wordCount;
  }

  static List<NoteEntity> toDomainList(List<NoteObject> entities) {
    return [for (final e in entities) toDomain(e)];
  }
}
