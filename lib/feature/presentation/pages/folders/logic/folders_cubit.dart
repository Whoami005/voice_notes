import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/Initializable_cubit.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/create_folder_sheet.dart';

part 'folders_state.dart';

class FoldersCubit extends RefreshableCubit<FoldersState> {
  final FolderRepository _repository;

  StreamSubscription<List<FolderEntity>>? _subscription;

  FoldersCubit({required FolderRepository repository})
    : _repository = repository;

  @override
  Future<void> init() async {
    try {
      emitLoading();
      if (isClosed) return;

      _subscription = _repository.watchAll().listen(
        (folders) => emitSuccess(FoldersState(folders: folders)),
        onError: logError,
        cancelOnError: false,
      );
    } catch (e, s) {
      final failure = logError(e, s);
      emitError(failure);
    }
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
    await execute(
      action: () async {
        await _repository.create(
          name: data.name,
          description: data.description,
          color: data.color,
          icon: data.icon,
        );
      },
    );
  }

  /// Обновить существующую папку
  Future<void> updateFolder(FolderEntity folder) async {
    try {
      await _repository.update(folder);
    } catch (e, s) {
      logError(e, s);
    }
  }

  /// Удалить папку
  Future<void> deleteFolder(String uid) async {
    try {
      await _repository.delete(uid);
    } catch (e, s) {
      logError(e, s);
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
