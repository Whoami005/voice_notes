part of 'folder_storage_cubit.dart';

class FolderStorageState extends StatusState {
  /// Папка, к которой относится экран. null — группа «Без папки».
  final FolderEntity? folder;

  /// Записи с аудио в папке, отсортированные по убыванию размера.
  final List<NoteAudioStats> notes;

  @override
  bool get isEmpty => notes.isEmpty;

  const FolderStorageState({
    super.status,
    super.failure,
    this.folder,
    this.notes = const [],
  });

  int get totalBytes {
    int sum = 0;
    for (final n in notes) sum += n.bytes;

    return sum;
  }

  Duration get totalDuration {
    int ms = 0;
    for (final n in notes) ms += n.duration.inMilliseconds;

    return Duration(milliseconds: ms);
  }

  @override
  FolderStorageState copyWith({
    Status? status,
    AppFailure? failure,
    FolderEntity? folder,
    List<NoteAudioStats>? notes,
  }) {
    return FolderStorageState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      folder: folder ?? this.folder,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [...super.props, folder, notes];
}
