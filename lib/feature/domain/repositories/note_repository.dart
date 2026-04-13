import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';

/// Репозиторий для управления заметками
abstract interface class NoteRepository {
  /// Получить все заметки, отсортированные по createdAt DESC
  Future<List<NoteEntity>> getAll();

  /// Получить заметку по UID
  Future<NoteEntity> getByUid(String uid);

  /// Получить заметки по UID папки
  Future<List<NoteEntity>> getByFolderId(String folderUid);

  /// Получить заметки без папки
  Future<List<NoteEntity>> getWithoutFolder();

  /// Создать новую заметку
  ///
  /// Если указан [audio] — к заметке прицепляется сохранённый оригинал
  /// аудиозаписи. Если null — заметка без аудио (текстовый ввод или
  /// выключенная настройка «Сохранять оригиналы»).
  ///
  /// Если указан [uid] — будет использован вместо автогенерации. Нужно для
  /// случая голосовой записи, когда uuid генерируется заранее (в момент
  /// старта записи) и используется как имя аудиофайла на диске.
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

  /// Обновить существующую заметку
  Future<NoteEntity> update(NoteEntity note);

  /// Удалить заметку по UID
  Future<void> delete(String uid);

  /// Переместить заметку в папку
  Future<void> moveToFolder(String noteUid, String? folderUid);

  /// Стрим всех заметок с реактивными обновлениями
  Stream<List<NoteEntity>> watchAll();

  /// Стрим заметок по UID папки (если null - возвращает заметки без папки)
  Stream<List<NoteEntity>> watchByFolderId(String folderUid);

  /// Стрим заметок без папки с реактивными обновлениями
  Stream<List<NoteEntity>> watchWithoutFolder();
}
