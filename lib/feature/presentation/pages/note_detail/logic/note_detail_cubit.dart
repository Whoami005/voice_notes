import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/async/initializable_async_cubits.dart';
import 'package:voice_notes/core/state/editable/editable.dart';
import 'package:voice_notes/core/state/effect/common_effects.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'note_detail_state.dart';

class NoteDetailCubit
    extends InitializableAsyncCubit<NoteDetailData, AppEffect> {
  final NoteRepository _noteRepository;
  final String noteId;

  NoteDetailCubit({
    required NoteRepository noteRepository,
    required this.noteId,
  }) : _noteRepository = noteRepository;

  @override
  Future<void> init() async {
    await load(() async {
      final note = await _noteRepository.getByUid(noteId);

      return NoteDetailData(note: Editable.fromValue(note));
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Editing mode
  // ─────────────────────────────────────────────────────────────

  /// Начать редактирование
  void startEditing() {
    transform((data) => data.copyWith(note: data.note.startEditing()));
  }

  /// Отменить редактирование (откатить к оригиналу)
  void cancelEditing() {
    transform((data) => data.copyWith(note: data.note.cancelEditing()));
  }

  // ─────────────────────────────────────────────────────────────
  // Text editing
  // ─────────────────────────────────────────────────────────────

  /// Обновить текст заметки
  void updateText(String text) {
    transform((data) {
      final updatedNote = data.note.modify((note) => note.copyWith(text: text));
      return data.copyWith(note: updatedNote);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Tags
  // ─────────────────────────────────────────────────────────────

  /// Добавить тег
  void addTag(String tagName) {
    final normalizedName = tagName.trim().toLowerCase();
    if (normalizedName.isEmpty) return;

    transform((data) {
      // Проверка на дубликат
      if (data.currentNote.tags.any((t) => t.name == normalizedName)) {
        return data;
      }

      final newTag = TagEntity(name: normalizedName, createdAt: DateTime.now());

      final updatedNote = data.note.modify(
        (note) => note.copyWith(tags: [...note.tags, newTag]),
      );

      return data.copyWith(note: updatedNote);
    });
  }

  /// Удалить тег
  void removeTag(TagEntity tag) {
    transform((data) {
      final updatedNote = data.note.modify(
        (note) => note.copyWith(
          tags: note.tags.where((t) => t.name != tag.name).toList(),
        ),
      );
      return data.copyWith(note: updatedNote);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Save & Delete
  // ─────────────────────────────────────────────────────────────

  /// Сохранить изменения в БД
  Future<void> saveNote() async {
    whenData((data) async {
      try {
        // Если нет изменений — просто выйти из редактирования
        if (data.note.isClean) {
          emitSuccess(data.copyWith(note: data.note.commit()));
          return;
        }

        // Подготовить заметку для сохранения
        final noteToSave = data.currentNote.copyWith(
          text: data.currentNote.text.trim(),
          updatedAt: DateTime.now(),
        );

        // Сохранить в БД
        final savedNote = await _noteRepository.update(noteToSave);

        // Зафиксировать с сохранённым значением
        emitSuccess(data.copyWith(note: data.note.commitWith(savedNote)));
        emitEffect(const ShowSuccessEffect('Заметка сохранена'));
      } catch (e, s) {
        emitEffect(ShowErrorEffect(logError(e, s)));
      }
    });
  }

  /// Удалить заметку
  Future<bool> deleteNote() async {
    try {
      await _noteRepository.delete(noteId);

      emitEffect(const ShowSuccessEffect('Заметка удалена'));
      return true;
    } catch (e, s) {
      emitEffect(ShowErrorEffect(logError(e, s)));
      return false;
    }
  }
}
