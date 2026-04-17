import 'dart:collection';

final class _Node<E> extends LinkedListEntry<_Node<E>> {
  _Node(this.value);

  final E value;
}

/// FIFO-очередь с уникальными элементами. Все операции честно O(1),
/// включая `remove(e)` по значению — нода достаётся из индекса и
/// отцепляется через `unlink()`.
///
/// Внутри — `LinkedList<_Node<E>>` + `HashMap<E, _Node<E>>`.
/// Цена: каждый элемент обёрнут в `_Node`, а `iterator` создаёт
/// `MappedIterable` на каждый доступ.
class IndexedUniqueQueue<E> extends Iterable<E> {
  final LinkedList<_Node<E>> _list = LinkedList<_Node<E>>();
  final HashMap<E, _Node<E>> _index = HashMap<E, _Node<E>>();

  @override
  Iterator<E> get iterator => _list.map((node) => node.value).iterator;

  @override
  int get length => _list.length;

  @override
  bool contains(Object? element) => _index.containsKey(element);

  /// Добавить в хвост. Возвращает `false`, если элемент уже есть.
  bool add(E element) {
    if (_index.containsKey(element)) return false;

    final node = _Node<E>(element);
    _list.add(node);
    _index[element] = node;
    return true;
  }

  /// Добавить в голову. Для requeue после неудачной обработки.
  bool addFirst(E element) {
    if (_index.containsKey(element)) return false;

    final node = _Node<E>(element);
    _list.addFirst(node);
    _index[element] = node;
    return true;
  }

  /// Массовое добавление. Возвращает число реально добавленных.
  int addAll(Iterable<E> elements) {
    var added = 0;
    for (final element in elements) {
      if (add(element)) added++;
    }
    return added;
  }

  /// Удалить конкретный элемент. Честно O(1) через индекс + `unlink`.
  bool remove(E element) {
    final node = _index.remove(element);
    if (node == null) return false;

    node.unlink();
    return true;
  }

  /// Извлечь голову. Бросит `StateError`, если пусто.
  E removeFirst() {
    final node = _list.first..unlink();
    _index.remove(node.value);

    return node.value;
  }

  @override
  E get first => _list.first.value;

  void clear() {
    _list.clear();
    _index.clear();
  }
}
