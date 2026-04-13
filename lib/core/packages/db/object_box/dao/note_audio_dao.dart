import 'package:objectbox/objectbox.dart' show Order;
import 'package:voice_notes/core/packages/db/object_box/dao/box_provider.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart'
    hide Order;
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';

/// DAO для работы с аудиозаписями заметок
class NoteAudioDao {
  const NoteAudioDao();

  /// Найти все аудио
  List<NoteAudioObject> findAll(BoxProvider box) {
    final query = box<NoteAudioObject>().query().build();

    final result = query.find();
    query.close();

    return result;
  }

  /// Найти аудио по UID папки, отсортированные по sizeBytes DESC
  List<NoteAudioObject> findByFolderUid(BoxProvider box, String folderUid) {
    final query = box<NoteAudioObject>()
        .query(NoteAudioObject_.folderUid.equals(folderUid))
        .order(NoteAudioObject_.sizeBytes, flags: Order.descending)
        .build();

    final result = query.find();
    query.close();

    return result;
  }

  /// Найти аудио без папки, отсортированные по sizeBytes DESC
  List<NoteAudioObject> findWithoutFolder(BoxProvider box) {
    final query = box<NoteAudioObject>()
        .query(NoteAudioObject_.folderUid.isNull())
        .order(NoteAudioObject_.sizeBytes, flags: Order.descending)
        .build();

    final result = query.find();
    query.close();

    return result;
  }

  /// Найти заметки-владельцы для списка audioId.
  ///
  /// Использует `link()` через ToOne relation с `oneOf` на id target entity —
  /// ObjectBox не поддерживает `oneOf` напрямую на relation-свойствах.
  List<NoteObject> findOwnerNotes(BoxProvider box, List<int> audioIds) {
    if (audioIds.isEmpty) return const [];

    final query =
        (box<NoteObject>().query()
              ..link(NoteObject_.audio, NoteAudioObject_.id.oneOf(audioIds)))
            .build();

    final result = query.find();
    query.close();

    return result;
  }

  /// Удалить аудио по списку ID
  void removeMany(BoxProvider box, List<int> ids) {
    if (ids.isEmpty) return;
    box<NoteAudioObject>().removeMany(ids);
  }

  /// Удалить все аудио
  void removeAll(BoxProvider box) => box<NoteAudioObject>().removeAll();

  // === Query Builders для watch ===

  /// Query builder для всех аудио
  QueryBuilder<NoteAudioObject> queryAll(BoxProvider box) =>
      box<NoteAudioObject>().query();
}
