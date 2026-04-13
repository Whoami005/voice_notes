import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';

abstract final class NoteAudioMapper {
  static NoteAudioEntity toDomain(NoteAudioObject obj) {
    return NoteAudioEntity(
      relativePath: obj.relativePath,
      sizeBytes: obj.sizeBytes,
      sampleRate: obj.sampleRate,
      duration: Duration(milliseconds: obj.durationMs),
    );
  }

  /// Создаёт ObjectBox-объект из domain-сущности.
  ///
  /// [folderUid] — денормализация из NoteObject для быстрых per-folder
  /// агрегаций в Storage screen. Nullable потому, что заметка может
  /// существовать без папки.
  static NoteAudioObject toEntity({
    required NoteAudioEntity entity,
    String? folderUid,
  }) {
    return NoteAudioObject(
      relativePath: entity.relativePath,
      sizeBytes: entity.sizeBytes,
      sampleRate: entity.sampleRate,
      durationMs: entity.duration.inMilliseconds,
      folderUid: folderUid,
    );
  }

  /// Обновляет существующий ObjectBox-объект значениями из domain-сущности.
  /// Если [folderUid] передан — обновляет и денормализацию.
  static void updateEntity(
    NoteAudioObject obj,
    NoteAudioEntity entity, {
    String? folderUid,
  }) {
    obj
      ..relativePath = entity.relativePath
      ..sizeBytes = entity.sizeBytes
      ..sampleRate = entity.sampleRate
      ..durationMs = entity.duration.inMilliseconds;

    if (folderUid != null) obj.folderUid = folderUid;
  }
}
