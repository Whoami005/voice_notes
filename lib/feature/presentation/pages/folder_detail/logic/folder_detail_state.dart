part of 'folder_detail_cubit.dart';

class FolderDetailData extends Equatable {
  final FolderEntity folder;
  final List<NoteEntity> notes;

  const FolderDetailData({required this.folder, this.notes = const []});

  List<DateGroup<NoteEntity>> groupedNotes({
    required String todayLabel,
    required String yesterdayLabel,
    required String localeCode,
  }) => DateGroup.groupByDate(
    notes,
    (note) => note.createdAt,
    todayLabel: todayLabel,
    yesterdayLabel: yesterdayLabel,
    localeCode: localeCode,
  );

  FolderDetailData copyWith({FolderEntity? folder, List<NoteEntity>? notes}) {
    return FolderDetailData(
      folder: folder ?? this.folder,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [folder, notes];
}
