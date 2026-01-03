import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/Initializable_cubit.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/create_folder_sheet.dart';

part 'folders_state.dart';

class FoldersCubit extends RefreshableCubit<FoldersState> {
  final FolderRepository _repository;

  FoldersCubit({required FolderRepository repository})
    : _repository = repository;

  @override
  Future<void> init() async {
    await load(() async {
      final folders = await _repository.getAll();
      return FoldersState(folders: folders);
    });
  }

  @override
  Future<void> refresh() async {
    await execute(
      action: () async {
        final folders = await _repository.getAll();
        emitSuccess(FoldersState(folders: folders));
      },
    );
  }

  /// Создать папку из результата CreateFolderSheet
  Future<void> createFolder(CreateFolderResult data) async {
    await transform((state) async {
      final folder = await _repository.create(
        name: data.name,
        description: data.description,
        color: data.color,
        icon: data.icon,
      );

      return state.copyWith(folders: [folder, ...state.folders]);
    });
  }

  /// Обновить существующую папку
  Future<void> updateFolder(FolderEntity folder) async {
    await transform((state) async {
      final updated = await _repository.update(folder);

      return state.copyWith(
        folders: [
          for (final f in state.folders)
            if (f.uid == updated.uid) updated else f,
        ],
      );
    });
  }

  /// Удалить папку
  Future<void> deleteFolder(String uid) async {
    await transform((state) async {
      await _repository.delete(uid);

      return state.copyWith(
        folders: [
          for (final f in state.folders)
            if (f.uid != uid) f,
        ],
      );
    });
  }
}
