import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/state/async/initializable_async_cubits.dart';
import 'package:voice_notes/core/state/effect/common_effects.dart';
import 'package:voice_notes/core/state/searchable/local_search_mixin.dart';
import 'package:voice_notes/core/state/searchable/search_matchers.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/create_folder_sheet.dart';

part 'folders_state.dart';

class FoldersCubit extends RefreshableAsyncCubit<FoldersState>
    with LocalSearchMixin {
  final FolderRepository _repository;

  StreamSubscription<List<FolderEntity>>? _subscription;

  FoldersCubit({required FolderRepository repository})
    : _repository = repository;

  @override
  void onSearch(String query) {
    whenData((data) => emitSuccess(data.copyWith(query: query)));
  }

  @override
  Future<void> init() async {
    try {
      emitLoading();
      if (isClosed) return;

      _subscription = _repository.watchAll().listen(
        (folders) => state.maybeWhen(
          success: (data) => emitSuccess(data.copyWith(folders: folders)),
          orElse: () => emitSuccess(FoldersState(folders: folders)),
        ),
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
    try {
      final folders = await _repository.getAll();
      emitSuccess(FoldersState(folders: folders));
    } catch (e, s) {
      emitEffect(ShowErrorEffect(logError(e, s)));
    }
  }

  /// Создать папку из результата CreateFolderSheet
  Future<void> createFolder(CreateFolderResult data) async {
    try {
      await _repository.create(
        name: data.name,
        description: data.description,
        color: data.color,
        icon: data.icon,
      );

      emitEffect(const ShowSuccessEffect('Папка создана'));
    } catch (e, s) {
      emitEffect(ShowErrorEffect(logError(e, s)));
    }
  }

  /// Обновить существующую папку
  Future<void> updateFolder(FolderEntity folder) async {
    try {
      await _repository.update(folder);
    } catch (e, s) {
      emitEffect(ShowErrorEffect(logError(e, s)));
    }
  }

  /// Удалить папку
  Future<void> deleteFolder(String uid) async {
    try {
      await _repository.delete(uid);

      emitEffect(const ShowSuccessEffect('Папка удалена'));
    } catch (e, s) {
      emitEffect(ShowErrorEffect(logError(e, s)));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
