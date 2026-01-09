import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/searchable/search_matchers.dart';
import 'package:voice_notes/core/state/searchable/searchable.dart';

/// Client-side searchable wrapper for pre-loaded data.
///
/// Filters items in memory based on search query.
/// Best for small lists or offline-first scenarios.
///
/// Example:
/// ```dart
/// final searchable = LocalSearchable(
///   items: folders,
///   matcher: SearchMatchers.byFields([
///     (f) => f.name,
///     (f) => f.description,
///   ]),
/// );
///
/// final filtered = searchable.updateQuery('work').filtered;
/// ```
class LocalSearchable<T> extends Equatable {
  final List<T> items;
  final String query;
  final SearchMatcher<T> matcher;
  final SearchHistory history;

  const LocalSearchable({
    required this.items,
    required this.matcher,
    this.query = '',
    this.history = const SearchHistory(),
  });

  // ─────────────────────────────────────────────────────────────
  // State Getters
  // ─────────────────────────────────────────────────────────────

  /// Is search active?
  bool get isSearching => query.isNotEmpty;

  /// Current search state for UI.
  SearchState get searchState {
    if (!isSearching) return SearchState.idle;

    return filtered.isEmpty ? SearchState.noResults : SearchState.hasResults;
  }

  /// Has any results (even when not searching)?
  bool get hasData => items.isNotEmpty;

  // ─────────────────────────────────────────────────────────────
  // Filtering
  // ─────────────────────────────────────────────────────────────

  /// Filtered items based on query.
  List<T> get filtered {
    if (!isSearching) return items;

    return [
      for (final item in items)
        if (matcher(item, query)) item,
    ];
  }

  /// Count of visible results.
  int get resultCount => filtered.length;

  /// Total count of items.
  int get totalCount => items.length;

  // ─────────────────────────────────────────────────────────────
  // Mutations
  // ─────────────────────────────────────────────────────────────

  /// Update search query.
  LocalSearchable<T> updateQuery(String newQuery) => LocalSearchable(
    items: items,
    query: newQuery,
    matcher: matcher,
    history: history,
  );

  /// Commit current query to history.
  LocalSearchable<T> commitSearch() => LocalSearchable(
    items: items,
    query: query,
    matcher: matcher,
    history: query.isNotEmpty ? history.addQuery(query) : history,
  );

  /// Clear search and optionally commit to history.
  LocalSearchable<T> clearSearch({bool commitToHistory = false}) =>
      LocalSearchable(
        items: items,
        matcher: matcher,
        history: commitToHistory && query.isNotEmpty
            ? history.addQuery(query)
            : history,
      );

  /// Update the underlying items (e.g., from stream).
  LocalSearchable<T> updateItems(List<T> newItems) => LocalSearchable(
    items: newItems,
    query: query,
    matcher: matcher,
    history: history,
  );

  /// Replace matcher (e.g., for different search modes).
  LocalSearchable<T> withMatcher(SearchMatcher<T> newMatcher) =>
      LocalSearchable(
        items: items,
        query: query,
        matcher: newMatcher,
        history: history,
      );

  @override
  List<Object?> get props => [items, query, history];

  @override
  String toString() =>
      'LocalSearchable(${filtered.length}/${items.length} items, '
      'query: "$query")';
}
