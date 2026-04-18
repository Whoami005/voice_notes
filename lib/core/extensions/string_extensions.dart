final _whitespaceRegex = RegExp(r'\s+');

extension StringWordCount on String {
  int get wordCount {
    final trimmed = trim();
    if (trimmed.isEmpty) return 0;

    return trimmed.split(_whitespaceRegex).length;
  }
}
