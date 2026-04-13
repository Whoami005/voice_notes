/// Форматирует количество байт в читаемую строку: `243 KB`, `1.5 MB`, `2.1 GB`.
abstract final class BytesFormatter {
  static const _suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];

  /// Использует десятичные единицы (1000, а не 1024) — это соответствует
  /// тому, как размеры показывают iOS/Android file managers.
  static String format(int bytes, {int fractionDigits = 1}) {
    if (bytes <= 0) return '0 B';

    double value = bytes.toDouble();
    int suffixIndex = 0;

    while (value >= 1000 && suffixIndex < _suffixes.length - 1) {
      value /= 1000;
      suffixIndex++;
    }

    final formatted = suffixIndex == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(fractionDigits);

    return '$formatted ${_suffixes[suffixIndex]}';
  }
}
