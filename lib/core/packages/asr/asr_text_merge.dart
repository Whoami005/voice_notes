abstract final class AsrTextMerge {
  static String merge(String accumulated, String incoming) {
    final left = accumulated.trim();
    final right = incoming.trim();

    if (left.isEmpty) return right;
    if (right.isEmpty) return left;

    final leftWords = left.split(RegExp(r'\s+'));
    final rightWords = right.split(RegExp(r'\s+'));
    final overlap = _findWordOverlap(leftWords, rightWords);

    if (overlap == 0) return '$left $right'.trim();

    final suffix = rightWords.skip(overlap).join(' ').trim();
    return suffix.isEmpty ? left : '$left $suffix';
  }

  static int _findWordOverlap(List<String> leftWords, List<String> rightWords) {
    final maxOverlap = leftWords.length < rightWords.length
        ? leftWords.length
        : rightWords.length;

    for (int overlap = maxOverlap; overlap > 0; overlap--) {
      final leftSlice = leftWords.sublist(leftWords.length - overlap);
      final rightSlice = rightWords.sublist(0, overlap);

      bool matches = true;
      for (int i = 0; i < overlap; i++) {
        if (_normalize(leftSlice[i]) != _normalize(rightSlice[i])) {
          matches = false;
          break;
        }
      }

      if (matches) return overlap;
    }

    return 0;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(
      RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true),
      '',
    );
  }
}
