/// Matcher function for search filtering.
///
/// Returns true if the item matches the query.
typedef SearchMatcher<T> = bool Function(T item, String query);

/// Common search matchers for typical use cases.
class SearchMatchers {
  SearchMatchers._();

  /// Match by a single string field.
  ///
  /// Example:
  /// ```dart
  /// SearchMatchers.byField((folder) => folder.name)
  /// ```
  static SearchMatcher<T> byField<T>(String? Function(T item) extractor) {
    return (item, query) {
      final value = extractor(item);
      if (value == null || value.isEmpty) return false;

      return value.toLowerCase().contains(query.toLowerCase());
    };
  }

  /// Match by multiple string fields (any match).
  ///
  /// Example:
  /// ```dart
  /// SearchMatchers.byFields([
  ///   (folder) => folder.name,
  ///   (folder) => folder.description,
  /// ])
  /// ```
  static SearchMatcher<T> byFields<T>(
    List<String? Function(T item)> extractors,
  ) {
    return (item, query) {
      final q = query.toLowerCase();

      return extractors.any((extractor) {
        final value = extractor(item);
        return value != null && value.toLowerCase().contains(q);
      });
    };
  }

  /// Match with custom predicate.
  ///
  /// Example:
  /// ```dart
  /// SearchMatchers.custom((folder, q) =>
  ///   folder.name.startsWith(q) || folder.tags.any((t) => t.contains(q))
  /// )
  /// ```
  static SearchMatcher<T> custom<T>(
    bool Function(T item, String query) predicate,
  ) {
    return predicate;
  }

  /// Combine multiple matchers (any match).
  static SearchMatcher<T> any<T>(List<SearchMatcher<T>> matchers) {
    return (item, query) => matchers.any((m) => m(item, query));
  }

  /// Combine multiple matchers (all must match).
  static SearchMatcher<T> all<T>(List<SearchMatcher<T>> matchers) {
    return (item, query) => matchers.every((m) => m(item, query));
  }
}
