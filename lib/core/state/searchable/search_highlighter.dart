import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Range of matched text for highlighting.
class MatchRange extends Equatable {
  final int start;
  final int end;

  const MatchRange(this.start, this.end);

  int get length => end - start;

  @override
  List<Object?> get props => [start, end];

  @override
  String toString() => 'MatchRange($start, $end)';
}

/// Utility for highlighting search matches in text.
class SearchHighlighter {
  SearchHighlighter._();

  /// Find all match ranges in text for given query.
  ///
  /// Returns list of [MatchRange] for each occurrence.
  static List<MatchRange> findMatches(String text, String query) {
    if (query.isEmpty || text.isEmpty) return const [];

    final ranges = <MatchRange>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;
      ranges.add(MatchRange(index, index + query.length));
      start = index + 1;
    }

    return ranges;
  }

  /// Build TextSpans with highlighted portions.
  ///
  /// Example:
  /// ```dart
  /// RichText(
  ///   text: TextSpan(
  ///     children: SearchHighlighter.buildHighlightedSpans(
  ///       folder.name,
  ///       searchQuery,
  ///       normalStyle: textTheme.bodyMedium,
  ///       highlightStyle: textTheme.bodyMedium?.copyWith(
  ///         backgroundColor: Colors.yellow.withOpacity(0.3),
  ///         fontWeight: FontWeight.bold,
  ///       ),
  ///     ),
  ///   ),
  /// )
  /// ```
  static List<TextSpan> buildHighlightedSpans(
    String text,
    String query, {
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    final matches = findMatches(text, query);

    if (matches.isEmpty) {
      return [TextSpan(text: text, style: normalStyle)];
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: normalStyle,
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: highlightStyle,
      ));

      lastEnd = match.end;
    }

    // Add remaining text after last match
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: normalStyle,
      ));
    }

    return spans;
  }

  /// Build a single TextSpan with highlighted children.
  static TextSpan buildHighlightedTextSpan(
    String text,
    String query, {
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    return TextSpan(
      children: buildHighlightedSpans(
        text,
        query,
        normalStyle: normalStyle,
        highlightStyle: highlightStyle,
      ),
    );
  }
}
