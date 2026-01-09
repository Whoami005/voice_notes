import 'dart:async';

import 'package:async/async.dart';
import 'package:voice_notes/core/state/base_state/base_cubit.dart';
import 'package:voice_notes/core/state/searchable/remote_searchable.dart';

/// Mixin for adding remote search capabilities to a BaseCubit.
///
/// Provides async search with debounce and request cancellation.
/// Implements stale-while-revalidate pattern: keeps old results
/// visible during loading.
///
/// Example:
/// ```dart
/// class NotesCubit extends RefreshableCubit<NotesState>
///     with RemoteSearchMixin<NoteEntity, NotesState> {
///
///   @override
///   RemoteSearchable<NoteEntity> getSearchable(NotesState state) =>
///       state.notes;
///
///   @override
///   NotesState updateSearchable(
///     NotesState state,
///     RemoteSearchable<NoteEntity> searchable,
///   ) => NotesState(notes: searchable);
///
///   @override
///   Future<List<NoteEntity>> performSearch(String query) =>
///       _repository.search(query);
/// }
/// ```
mixin RemoteSearchMixin<T, S> on BaseCubit<S> {
  Timer? _searchDebounceTimer;
  CancelableOperation<List<T>>? _pendingSearch;

  /// Debounce duration for search. Override to customize.
  Duration get searchDebounce => const Duration(milliseconds: 500);

  /// Extract Searchable from state. Must be implemented.
  RemoteSearchable<T> getSearchable(S state);

  /// Create new state with updated Searchable. Must be implemented.
  S updateSearchable(S state, RemoteSearchable<T> searchable);

  /// Perform the actual search. Must be implemented.
  Future<List<T>> performSearch(String query);

  /// Start search with debounce and cancellation.
  void search(String query) {
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      clearSearch();
      return;
    }

    _searchDebounceTimer = Timer(searchDebounce, () => _executeSearch(query));
  }

  /// Start search immediately without debounce.
  void searchImmediate(String query) {
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      clearSearch();
      return;
    }

    _executeSearch(query);
  }

  Future<void> _executeSearch(String query) async {
    // Cancel previous request
    await _pendingSearch?.cancel();

    // Mark as searching (keeps old results)
    transform((state) {
      final searchable = getSearchable(state).startSearch(query);
      return updateSearchable(state, searchable);
    });

    // Create cancellable operation
    _pendingSearch = CancelableOperation.fromFuture(performSearch(query));

    try {
      final results = await _pendingSearch!.value;

      // Only update if not cancelled
      if (!(_pendingSearch?.isCanceled ?? true)) {
        transform((state) {
          final searchable = getSearchable(state).success(results);
          return updateSearchable(state, searchable);
        });
      }
    } catch (e, s) {
      final failure = logError(e, s);
      transform((state) {
        final searchable = getSearchable(state).failure(failure.message);
        return updateSearchable(state, searchable);
      });
    }
  }

  /// Clear search and reset to idle.
  void clearSearch() {
    _searchDebounceTimer?.cancel();
    _pendingSearch?.cancel();
    transform((state) {
      final searchable = getSearchable(state).clear();
      return updateSearchable(state, searchable);
    });
  }

  /// Retry last failed search.
  void retrySearch() {
    final data = dataOrNull;
    if (data == null) return;
    final currentQuery = getSearchable(data).query;
    if (currentQuery.isNotEmpty) {
      searchImmediate(currentQuery);
    }
  }

  @override
  Future<void> close() async {
    _searchDebounceTimer?.cancel();
    await _pendingSearch?.cancel();
    return super.close();
  }
}
