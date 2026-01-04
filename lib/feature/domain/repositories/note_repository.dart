import 'package:voice_notes/feature/domain/entities/note_entity.dart';

/// Репозиторий для управления заметками
abstract interface class NoteRepository {
  /// Получить все заметки, отсортированные по createdAt DESC
  Future<List<NoteEntity>> getAll();

  /// Получить заметку по UID
  Future<NoteEntity?> getByUid(String uid);

  /// Получить заметки по ID папки
  Future<List<NoteEntity>> getByFolderId(String folderUid);

  /// Получить заметки без папки
  Future<List<NoteEntity>> getWithoutFolder();

  /// Создать новую заметку
  Future<NoteEntity> create({
    required String text,
    required Duration duration,
    required String modelName,
    required String language,
    required int wordCount,
    String? folderUid,
    List<String> tagNames = const [],
    bool hasAudio = true,
  });

  /// Обновить существующую заметку
  Future<NoteEntity> update(NoteEntity note);

  /// Удалить заметку по UID
  Future<void> delete(String uid);

  /// Переместить заметку в папку
  Future<void> moveToFolder(String noteUid, String? folderUid);

  /// Стрим всех заметок с реактивными обновлениями
  Stream<List<NoteEntity>> watchAll();

  /// Стрим заметок по ID папки с реактивными обновлениями
  Stream<List<NoteEntity>> watchByFolderId(String folderUid);

  /// Стрим заметок без папки с реактивными обновлениями
  Stream<List<NoteEntity>> watchWithoutFolder();
}
