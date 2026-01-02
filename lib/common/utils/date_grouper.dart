import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Группа элементов, объединённых по дате
class DateGroup<T> extends Equatable {
  final String label;
  final List<T> items;

  const DateGroup({required this.label, required this.items});

  @override
  List<Object?> get props => [label, items];

  /// Группировка: "Сегодня", "Вчера",
  /// затем конкретные даты ("15 декабря", "14 декабря"...)
  static List<DateGroup<T>> groupByDate<T>(
    List<T> items,
    DateTime Function(T) getDate,
  ) {
    if (items.isEmpty) return const [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<T>>{};

    for (final item in items) {
      final itemDate = getDate(item);
      final dateOnly = DateTime(itemDate.year, itemDate.month, itemDate.day);

      final label = _getDateLabel(dateOnly, today, yesterday);

      groups.putIfAbsent(label, () => []).add(item);
    }

    return [
      for (final entry in groups.entries)
        DateGroup(label: entry.key, items: entry.value),
    ];
  }

  static String _getDateLabel(
    DateTime date,
    DateTime today,
    DateTime yesterday,
  ) {
    if (date == today) return 'Сегодня';
    if (date == yesterday) return 'Вчера';

    final formatter = DateFormat('d MMMM', 'ru');
    return formatter.format(date);
  }
}
