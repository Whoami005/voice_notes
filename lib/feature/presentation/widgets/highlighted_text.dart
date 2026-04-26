import 'package:flutter/material.dart';

/// Renders [text] highlighting every case-insensitive occurrence of [query].
///
/// When [query] is empty, falls back to a plain [Text] with [style].
/// Highlight spans are styled with [highlightStyle]; if not provided, the
/// effective base style is used with the highlight `color` applied on top.
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final Color? highlightColor;
  final int? maxLines;
  final TextOverflow overflow;

  const HighlightedText({
    required this.text,
    required this.query,
    super.key,
    this.style,
    this.highlightStyle,
    this.highlightColor,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final spans = _buildSpans(context);

    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.trim().toLowerCase();
    final spans = <TextSpan>[];

    final effectiveHighlight =
        highlightStyle ??
        (style ?? const TextStyle()).copyWith(
          color: highlightColor ?? Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        );

    int cursor = 0;

    while (cursor < text.length) {
      final matchAt = lowerText.indexOf(lowerQuery, cursor);
      if (matchAt == -1) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }

      if (matchAt > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, matchAt)));
      }
      spans.add(
        TextSpan(
          text: text.substring(matchAt, matchAt + query.length),
          style: effectiveHighlight,
        ),
      );

      cursor = matchAt + query.length;
    }

    return spans;
  }
}
