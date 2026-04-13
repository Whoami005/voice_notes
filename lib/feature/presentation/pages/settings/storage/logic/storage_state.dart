part of 'storage_cubit.dart';

class StorageState extends StatusState {
  /// Общая статистика хранилища.
  final StorageOverviewStats overview;

  /// Список папок с аудио, отсортированный по убыванию размера.
  final List<FolderStorageStats> folders;

  const StorageState({
    super.status,
    super.failure,
    this.overview = const StorageOverviewStats.empty(),
    this.folders = const [],
  });

  @override
  bool get isEmpty => overview.isEmpty;

  @override
  StorageState copyWith({
    Status? status,
    AppFailure? failure,
    StorageOverviewStats? overview,
    List<FolderStorageStats>? folders,
  }) {
    return StorageState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      overview: overview ?? this.overview,
      folders: folders ?? this.folders,
    );
  }

  @override
  List<Object?> get props => [...super.props, overview, folders];
}
