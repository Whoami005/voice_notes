import 'package:flutter/widgets.dart';

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

extension WidgetListX on List<Widget> {
  List<Widget> separatedBy(Widget separator, {bool addLeading = false}) {
    if (isEmpty) return this;

    return [
      if (addLeading) separator,
      for (var i = 0; i < length; i++) ...[
        this[i],
        if (i != length - 1) separator,
      ],
    ];
  }
}
