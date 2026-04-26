part of 'folder_search_cubit.dart';

class FolderSearchState extends StatusState {
  final List<FolderEntity> folders;
  final String query;

  @override
  bool get isEmpty => folders.isEmpty;

  const FolderSearchState({
    super.status,
    super.failure,
    this.folders = const [],
    this.query = '',
  });

  static final SearchMatcher<FolderEntity> _matcher =
      SearchMatchers.byFields<FolderEntity>([
        (f) => f.name,
        (f) => f.description,
      ]);

  bool get isSearching => query.isNotEmpty;

  List<FolderEntity> get filteredFolders {
    if (!isSearching) return folders;

    return [
      for (final f in folders)
        if (_matcher(f, query)) f,
    ];
  }

  @override
  FolderSearchState copyWith({
    Status? status,
    AppFailure? failure,
    List<FolderEntity>? folders,
    String? query,
  }) => FolderSearchState(
    status: status ?? this.status,
    failure: failure ?? this.failure,
    folders: folders ?? this.folders,
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [...super.props, folders, query];
}
