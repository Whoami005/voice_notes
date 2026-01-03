part of 'note_detail_cubit.dart';

class NoteDetailData extends Equatable {
  final NoteEntity note;
  final bool isEditing;

  const NoteDetailData({
    required this.note,
    this.isEditing = false,
  });

  NoteDetailData copyWith({
    NoteEntity? note,
    bool? isEditing,
  }) {
    return NoteDetailData(
      note: note ?? this.note,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [note, isEditing];
}
