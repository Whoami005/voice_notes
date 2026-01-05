part of 'note_detail_cubit.dart';

class NoteDetailData extends Equatable {
  final Editable<NoteEntity> note;

  /// Режим редактирования?
  bool get isEditing => note.isEditing;

  /// Есть несохранённые изменения?
  bool get hasChanges => note.hasChanges;

  /// Текущая заметка (для отображения)
  NoteEntity get currentNote => note.current;

  /// Оригинальная заметка (до редактирования)
  NoteEntity get originalNote => note.original;

  const NoteDetailData({required this.note});

  NoteDetailData copyWith({Editable<NoteEntity>? note}) {
    return NoteDetailData(note: note ?? this.note);
  }

  @override
  List<Object?> get props => [note];
}
