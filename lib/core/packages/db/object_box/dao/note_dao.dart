import 'package:objectbox/objectbox.dart' show Order;
import 'package:voice_notes/core/packages/db/object_box/dao/box_provider.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart'
    hide Order;
import 'package:voice_notes/feature/data/local/models/note_object.dart';

/// DAO для работы с заметками
class NoteDao {
  const NoteDao();

  /// Найти все заметки, отсортированные по createdAt DESC
  List<NoteObject> findAll(BoxProvider box) {
    final query = box<NoteObject>()
        .query()
        .order(NoteObject_.createdAt, flags: Order.descending)
        .build();

    final result = query.find();
    query.close();

    return result;
  }

  /// Найти заметку по UID
  NoteObject? findByUid(BoxProvider box, String uid) {
    final query = box<NoteObject>().query(NoteObject_.uid.equals(uid)).build();

    final result = query.findFirst();
    query.close();

    return result;
  }

  /// Найти заметки по ID папки
  List<NoteObject> findByFolderId(BoxProvider box, int folderId) {
    final query = box<NoteObject>()
        .query(NoteObject_.folder.equals(folderId))
        .order(NoteObject_.createdAt, flags: Order.descending)
        .build();

    final result = query.find();
    query.close();

    return result;
  }

  /// Найти заметки без папки
  List<NoteObject> findWithoutFolder(BoxProvider box) {
    final query = box<NoteObject>()
        .query(NoteObject_.folder.isNull())
        .order(NoteObject_.createdAt, flags: Order.descending)
        .build();

    final result = query.find();
    query.close();

    return result;
  }

  /// Сохранить или обновить заметку
  NoteObject put(
    BoxProvider box,
    NoteObject note, {
    PutMode mode = PutMode.put,
  }) {
    box<NoteObject>().put(note, mode: mode);
    return note;
  }

  /// Удалить заметку по ID
  void remove(BoxProvider box, int id) => box<NoteObject>().remove(id);

  // === Query Builders для watch ===

  /// Query builder для всех заметок
  QueryBuilder<NoteObject> queryAll(BoxProvider box) {
    return box<NoteObject>().query().order(
      NoteObject_.createdAt,
      flags: Order.descending,
    );
  }

  /// Query builder для заметок по ID папки
  QueryBuilder<NoteObject> queryByFolderId(BoxProvider box, int folderId) {
    return box<NoteObject>()
        .query(NoteObject_.folder.equals(folderId))
        .order(NoteObject_.createdAt, flags: Order.descending);
  }

  /// Query builder для заметок без папки
  QueryBuilder<NoteObject> queryWithoutFolder(BoxProvider box) {
    return box<NoteObject>()
        .query(NoteObject_.folder.isNull())
        .order(NoteObject_.createdAt, flags: Order.descending);
  }
}
