part of 'folders_cubit.dart';

class FoldersState extends Equatable {
  final List<FolderEntity> folders;

  const FoldersState({this.folders = const []});

  FoldersState copyWith({List<FolderEntity>? folders}) =>
      FoldersState(folders: folders ?? this.folders);

  @override
  List<Object> get props => [folders];
}
