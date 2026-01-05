extension UniqueExtension<T> on List<T> {
  /// Возвращает список с уникальными элементами (по hashCode и ==)
  List<T> unique() {
    return toSet().toList();
  }

  /// Возвращает уникальные элементы на основе селектора
  /// Сохраняет порядок первого вхождения
  List<T> uniqueBy<K>(K Function(T item) selector) {
    final seen = <K>{};
    return where((item) => seen.add(selector(item))).toList();
  }
}
