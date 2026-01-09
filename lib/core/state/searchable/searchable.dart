import 'package:equatable/equatable.dart';

/// Search status for UI state management.
enum SearchState {
  /// No active search
  idle,

  /// Search in progress (loading indicator)
  searching,

  /// Has results
  hasResults,

  /// Search completed, no results
  noResults,

  /// Search failed
  error;

  bool get isIdle => this == SearchState.idle;

  bool get isSearching => this == SearchState.searching;

  bool get isHasResults => this == SearchState.hasResults;

  bool get isNoResults => this == SearchState.noResults;

  bool get isError => this == SearchState.error;
}

/// Tracks recent search queries.
///
/// Maintains a limited history of search queries for suggestions.
class SearchHistory extends Equatable {
  final List<String> queries;
  final int maxSize;

  const SearchHistory({this.queries = const [], this.maxSize = 10});

  /// Add a new query to history (moves existing to top, limits size).
  SearchHistory addQuery(String query) {
    if (query.trim().isEmpty) return this;
    final trimmed = query.trim();
    final filtered = queries.where((q) => q != trimmed).toList();
    final updated = [trimmed, ...filtered].take(maxSize).toList();

    return SearchHistory(queries: updated, maxSize: maxSize);
  }

  /// Remove a specific query from history.
  SearchHistory removeQuery(String query) => SearchHistory(
    queries: [
      for (final q in queries)
        if (q != query) q,
    ],
    maxSize: maxSize,
  );

  /// Clear all history.
  SearchHistory clear() => SearchHistory(maxSize: maxSize);

  /// Check if history is empty.
  bool get isEmpty => queries.isEmpty;

  /// Check if history has entries.
  bool get isNotEmpty => queries.isNotEmpty;

  @override
  List<Object?> get props => [queries, maxSize];

  @override
  String toString() => 'SearchHistory(${queries.length} queries)';
}
