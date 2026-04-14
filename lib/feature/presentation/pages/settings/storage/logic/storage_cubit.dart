import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/status/initializable_status_cubits.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/feature/domain/entities/folder_storage_stats.dart';
import 'package:voice_notes/feature/domain/entities/storage_overview_stats.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';

part 'storage_state.dart';

/// Cubit главного экрана хранилища.
class StorageCubit extends RefreshableStatusCubit<StorageState> {
  final StorageStatsRepository _repository;

  StreamSubscription<StorageState>? _subscription;

  StorageCubit({required StorageStatsRepository repository})
    : _repository = repository,
      super(const StorageState());

  @override
  Future<void> init() async {
    emitLoading();
    try {
      _subscription = Rx.combineLatest2(
        _repository.watchOverview(),
        _repository.watchFolderStats(),
        (overview, folders) =>
            state.copyWith(overview: overview, folders: folders),
      ).listen(emitSuccess, onError: _onStreamError, cancelOnError: false);
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  @override
  Future<void> refresh() => guard(() async {
    final (overview, folders) = await (
      _repository.getOverview(),
      _repository.getFolderStats(),
    ).wait;

    return state.copyWith(overview: overview, folders: folders);
  });

  Future<void> deleteFolderAudio(String? folderUid) async {
    try {
      await _repository.deleteFolderAudio(folderUid);
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  Future<void> deleteAllAudio() async {
    try {
      await _repository.deleteAllAudio();
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Private
  // ─────────────────────────────────────────────────────────────

  void _onStreamError(Object error, StackTrace stackTrace) {
    emitError(logError(error, stackTrace));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
