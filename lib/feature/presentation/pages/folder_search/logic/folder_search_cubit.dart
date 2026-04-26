import 'dart:async';

import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/searchable/local_search_mixin.dart';
import 'package:voice_notes/core/state/searchable/search_matchers.dart';
import 'package:voice_notes/core/state/status/initializable_status_cubits.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';

part 'folder_search_state.dart';

/// Cubit for the dedicated folder search screen.
///
/// Subscribes to the same `FolderRepository.watchAll()` stream so results
/// stay live while the user types. The search query is debounced via
/// [LocalSearchMixin] (500ms by default).
class FolderSearchCubit extends InitializableStatusCubit<FolderSearchState>
    with LocalSearchMixin {
  final FolderRepository _repository;

  StreamSubscription<List<FolderEntity>>? _subscription;

  FolderSearchCubit({required FolderRepository repository})
    : _repository = repository,
      super(const FolderSearchState());

  @override
  void onSearch(String query) {
    emitSuccess(state.copyWith(query: query));
  }

  @override
  Future<void> init() async {
    emitLoading();
    if (isClosed) return;

    _subscription ??= _repository.watchAll().listen(
      (folders) => emitSuccess(state.copyWith(folders: folders)),
      onError: logError,
      cancelOnError: false,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
