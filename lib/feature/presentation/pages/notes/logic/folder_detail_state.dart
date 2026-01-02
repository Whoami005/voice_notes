part of 'folder_detail_cubit.dart';

class FolderDetailData extends Equatable {
  final FolderEntity? folder;
  final List<NoteEntity> notes;

  const FolderDetailData({required this.folder, this.notes = const []});

  List<DateGroup<NoteEntity>> get groupedNotes =>
      DateGrouper.groupByDate(notes, (note) => note.createdAt);

  FolderDetailData copyWith({FolderEntity? folder, List<NoteEntity>? notes}) {
    return FolderDetailData(
      folder: folder ?? this.folder,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [folder, notes];
}
