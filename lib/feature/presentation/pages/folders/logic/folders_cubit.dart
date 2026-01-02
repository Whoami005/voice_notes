import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/base_cubit.dart';
import 'package:voice_notes/core/state/initializable.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/create_folder_sheet.dart';

part 'folders_state.dart';

class FoldersCubit extends BaseCubit<FoldersState> implements Refreshable {
  final FolderRepository _repository;

  FoldersCubit({required FolderRepository repository})
    : _repository = repository;

  @override
  Future<void> init() async {
    await guard(() async {
      final folders = await _repository.getAll();
      return FoldersState(folders: folders);
    });
  }

  @override
  Future<void> refresh() async {
    await updateSafe((_) async {
      final folders = await _repository.getAll();
      return FoldersState(folders: folders);
    });
  }

  /// Создать папку из результата CreateFolderSheet
  Future<void> createFolder(CreateFolderResult data) async {
    await safeExecute(
      action: () async {
        final folder = await _repository.create(
          name: data.name,
          description: data.description,
          color: data.color,
          icon: data.icon,
        );
        update((state) => state.copyWith(folders: [folder, ...state.folders]));
      },
      onError: (failure) {
        print(failure.message);
      }
    );
  }

  /// Обновить существующую папку
  Future<void> updateFolder(FolderEntity folder) async {
    await safeExecute(
      action: () async {
        final updated = await _repository.update(folder);
        update(
          (state) => state.copyWith(
            folders: [
              for (final f in state.folders)
                if (f.uid == updated.uid) updated else f,
            ],
          ),
        );
      },
    );
  }

  /// Удалить папку
  Future<void> deleteFolder(String uid) async {
    await safeExecute(
      action: () async {
        await _repository.delete(uid);
        update(
          (state) => state.copyWith(
            folders: [
              for (final f in state.folders)
                if (f.uid != uid) f,
            ],
          ),
        );
      },
    );
  }
}
