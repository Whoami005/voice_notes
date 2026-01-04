import 'package:objectbox/objectbox.dart' show Order;
import 'package:voice_notes/core/packages/db/object_box/dao/box_provider.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart'
    hide Order;
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';

/// DAO для работы с папками
class FolderDao {
  const FolderDao();

  /// Найти все папки, отсортированные по updatedAt DESC
  List<FolderObject> findAll(BoxProvider box) {
    final query = box<FolderObject>()
        .query()
        .order(FolderObject_.updatedAt, flags: Order.descending)
        .build();

    final result = query.find();
    query.close();

    return result;
  }

  /// Найти папку по UID
  FolderObject? findByUid(BoxProvider box, String uid) {
    final query = box<FolderObject>()
        .query(FolderObject_.uid.equals(uid))
        .build();

    final result = query.findFirst();
    query.close();

    return result;
  }

  /// Найти папку по ID
  FolderObject? findById(BoxProvider box, int id) =>
      box<FolderObject>().get(id);

  /// Сохранить или обновить папку
  FolderObject put(
    BoxProvider box,
    FolderObject folder, {
    PutMode mode = PutMode.put,
  }) {
    box<FolderObject>().put(folder, mode: mode);
    return folder;
  }

  /// Удалить папку по ID
  void remove(BoxProvider box, int id) => box<FolderObject>().remove(id);

  /// Удалить папку вместе со всеми заметками
  void removeWithNotes(BoxProvider box, FolderObject folder) {
    final noteIds = [for (final note in folder.notes) note.id];
    box<NoteObject>().removeMany(noteIds);
    box<FolderObject>().remove(folder.id);
  }

  /// Обновить timestamp папки (для триггера watch)
  void touch(BoxProvider box, FolderObject? folder) {
    if (folder == null) return;
    folder.updatedAt = DateTime.now();
    box<FolderObject>().put(folder, mode: PutMode.update);
  }

  /// Получить количество заметок в папке
  int getNotesCount(BoxProvider box, int folderId) {
    final folder = box<FolderObject>().get(folderId);
    return folder?.notes.length ?? 0;
  }

  // === Query Builders для watch ===

  /// Query builder для всех папок
  QueryBuilder<FolderObject> queryAll(BoxProvider box) {
    return box<FolderObject>().query().order(
      FolderObject_.updatedAt,
      flags: Order.descending,
    );
  }

  /// Query builder для папки по UID
  QueryBuilder<FolderObject> queryByUid(BoxProvider box, String uid) {
    return box<FolderObject>().query(FolderObject_.uid.equals(uid));
  }
}
