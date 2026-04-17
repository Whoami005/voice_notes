import 'dart:collection';

/// FIFO-очередь с уникальными элементами (FIFO + Set-семантика).
/// Порядок — вставки, дубликаты игнорируются.
///
/// Внутри — пара `Queue<E>` + `Set<E>`. Инвариант: элемент либо
/// в обоих контейнерах, либо ни в одном. Complexity: `add`,
/// `addFirst`, `removeFirst`, `contains` — O(1); `remove` — O(n)
/// из-за `Queue.remove`.
class UniqueQueue<E> extends Iterable<E> {
  final Queue<E> _queue = Queue<E>();
  final Set<E> _members = <E>{};

  @override
  Iterator<E> get iterator => _queue.iterator;

  @override
  int get length => _queue.length;

  @override
  bool contains(Object? element) => _members.contains(element);

  /// Добавить в хвост. Возвращает `false`, если элемент уже есть.
  bool add(E element) {
    if (!_members.add(element)) return false;

    _queue.add(element);
    return true;
  }

  /// Добавить в голову. Для requeue после неудачной обработки.
  bool addFirst(E element) {
    if (!_members.add(element)) return false;

    _queue.addFirst(element);
    return true;
  }

  /// Массовое добавление. Возвращает число реально добавленных.
  int addAll(Iterable<E> elements) {
    int added = 0;
    for (final element in elements) if (add(element)) added++;

    return added;
  }

  /// Удалить конкретный элемент. O(n).
  bool remove(E element) {
    if (!_members.remove(element)) return false;

    _queue.remove(element);
    return true;
  }

  /// Извлечь голову. Бросит `StateError`, если пусто.
  E removeFirst() {
    final element = _queue.removeFirst();
    _members.remove(element);
    return element;
  }

  @override
  E get first => _queue.first;

  void clear() {
    _queue.clear();
    _members.clear();
  }
}
