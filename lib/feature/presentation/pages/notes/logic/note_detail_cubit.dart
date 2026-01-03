import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_exception.dart';
import 'package:voice_notes/core/state/base_cubit.dart';
import 'package:voice_notes/core/state/initializable.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'note_detail_state.dart';

class NoteDetailCubit extends BaseCubit<NoteDetailData>
    implements Initializable {
  final NoteRepository _noteRepository;
  final String noteId;

  NoteDetailCubit({
    required NoteRepository noteRepository,
    required this.noteId,
  }) : _noteRepository = noteRepository;

  @override
  Future<void> init() async {
    await guard(() async {
      final note = await _noteRepository.getByUid(noteId);
      if (note == null) throw const CustomException('Заметка не найдена');

      return NoteDetailData(note: note);
    });
  }

  void toggleEditing() {
    update((data) => data.copyWith(isEditing: !data.isEditing));
  }

  Future<void> updateNote({String? text, List<TagEntity>? tags}) async {
    await withData((data) async {
      final updatedNote = data.note.copyWith(
        text: text,
        tags: tags,
        updatedAt: DateTime.now(),
      );

      await safeExecute(
        action: () async {
          final savedNote = await _noteRepository.update(updatedNote);
          emitSuccess(data.copyWith(note: savedNote, isEditing: text == null));
        },
      );
    });
  }

  Future<void> addTag(String tagName) async {
    await withData((data) async {
      final normalizedName = tagName.trim().toLowerCase();
      if (normalizedName.isEmpty) return;
      if (data.note.tags.any((t) => t.name == normalizedName)) return;

      final newTag = TagEntity(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        name: normalizedName,
        createdAt: DateTime.now(),
      );

      final updatedTags = [...data.note.tags, newTag];
      await updateNote(tags: updatedTags);
    });
  }

  Future<void> removeTag(TagEntity tag) async {
    await withData((data) async {
      final updatedTags = data.note.tags
          .where((t) => t.uid != tag.uid)
          .toList();

      await updateNote(tags: updatedTags);
    });
  }

  Future<bool> deleteNote() async {
    try {
      await _noteRepository.delete(noteId);
      return true;
    } catch (e, s) {
      addError(e, s);

      return false;
    }
  }
}
