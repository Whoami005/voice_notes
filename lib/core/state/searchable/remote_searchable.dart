import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/searchable/searchable.dart';

/// Remote searchable wrapper for async DB/backend queries.
///
/// Implements stale-while-revalidate pattern:
/// - Keeps old results visible during loading
/// - Shows subtle loading indicator via [isReloading]
/// - Only replaces results on successful fetch
/// - Keeps old results on error (show toast instead)
///
/// Example:
/// ```dart
/// // Start search - keeps old results
/// searchable = searchable.startSearch('meeting');
///
/// // On success - replace results
/// searchable = searchable.success(newResults);
///
/// // On error - keep old results
/// searchable = searchable.failure('Network error');
/// ```
class RemoteSearchable<T> extends Equatable {
  /// Current committed query (last successful search).
  final String query;

  /// Query currently being fetched (for stale-while-revalidate).
  final String? pendingQuery;

  /// Current visible results.
  final List<T> results;

  /// Current search state.
  final SearchState searchState;

  /// Search history for suggestions.
  final SearchHistory history;

  /// Error message from last failed search.
  final String? errorMessage;

  const RemoteSearchable({
    this.query = '',
    this.pendingQuery,
    this.results = const [],
    this.searchState = SearchState.idle,
    this.history = const SearchHistory(),
    this.errorMessage,
  });

  // ─────────────────────────────────────────────────────────────
  // State Getters
  // ─────────────────────────────────────────────────────────────

  /// Are we currently loading new results?
  bool get isSearching => searchState == SearchState.searching;

  /// Is a new query being fetched while showing old results?
  bool get isReloading => pendingQuery != null && results.isNotEmpty;

  /// Has any data to display?
  bool get hasData => results.isNotEmpty;

  /// Should show empty state (only when idle with no results)?
  bool get showEmptyState =>
      searchState.isNoResults || (searchState.isIdle && results.isEmpty);

  /// Has an error occurred?
  bool get hasError => searchState == SearchState.error;

  /// Has search results?
  bool get hasResults => searchState == SearchState.hasResults;

  /// Count of results.
  int get resultCount => results.length;

  /// Query to display in search field.
  String get displayQuery => pendingQuery ?? query;

  // ─────────────────────────────────────────────────────────────
  // Mutations
  // ─────────────────────────────────────────────────────────────

  /// Start search - keeps old results visible.
  RemoteSearchable<T> startSearch(String newQuery) => RemoteSearchable(
    query: query,
    pendingQuery: newQuery,
    results: results,
    // Keep old results
    searchState: SearchState.searching,
    history: history,
  );

  /// Mark search as successful with new results.
  RemoteSearchable<T> success(List<T> newResults) {
    final committedQuery = pendingQuery ?? query;

    return RemoteSearchable(
      query: committedQuery,
      results: newResults,
      searchState: newResults.isEmpty
          ? SearchState.noResults
          : SearchState.hasResults,
      history: committedQuery.isNotEmpty
          ? history.addQuery(committedQuery)
          : history,
    );
  }

  /// Mark search as failed - keeps old results.
  RemoteSearchable<T> failure(String message) => RemoteSearchable(
    query: query,
    results: results,
    // Keep old results
    searchState: SearchState.error,
    history: history,
    errorMessage: message,
  );

  /// Clear search completely.
  RemoteSearchable<T> clear() => RemoteSearchable(history: history);

  /// Retry last failed search.
  RemoteSearchable<T> retry() => startSearch(query);

  /// Set initial results (before any search).
  RemoteSearchable<T> withInitialResults(List<T> initialResults) =>
      RemoteSearchable(
        query: query,
        pendingQuery: pendingQuery,
        results: initialResults,
        searchState: searchState.isIdle
            ? (initialResults.isEmpty
                  ? SearchState.idle
                  : SearchState.hasResults)
            : searchState,
        history: history,
      );

  @override
  List<Object?> get props => [
    query,
    pendingQuery,
    results,
    searchState,
    history,
    errorMessage,
  ];

  @override
  String toString() =>
      'RemoteSearchable(query: "$displayQuery", '
      '${results.length} results, state: $searchState)';
}
