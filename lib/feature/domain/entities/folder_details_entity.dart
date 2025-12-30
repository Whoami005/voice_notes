import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';

/// Папка с полным списком заметок (для детального просмотра).
class FolderDetailsEntity {
  final FolderEntity folder;
  final List<NoteEntity> notes;

  const FolderDetailsEntity({
    required this.folder,
    required this.notes,
  });
}
