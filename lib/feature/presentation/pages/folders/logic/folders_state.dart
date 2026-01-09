part of 'folders_cubit.dart';

class FoldersState extends Equatable {
  final List<FolderEntity> folders;
  final String query;

  const FoldersState({this.query = '', this.folders = const []});

  /// Matcher создаётся один раз как статик.
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

  FoldersState copyWith({List<FolderEntity>? folders, String? query}) =>
      FoldersState(
        folders: folders ?? this.folders,
        query: query ?? this.query,
      );

  @override
  List<Object> get props => [folders, query];
}
