// Для комментариев
// ignore_for_file: lines_longer_than_80_chars

/// Утилита для работы со списками в состоянии (State)
/// Предоставляет типобезопасные методы для обновления, удаления и замены элементов
///
/// ## Когда использовать
///
/// **Используйте ручной collection-for для простых операций:**
/// ```dart
/// // Конкретно, однострочно
/// [for (f in folders) if (f.uid == id) updated else f]
/// ```
///
/// **Используйте ListUpdater/Extensions для:**
/// - Сложных многошаговых трансформаций
/// - Цепочек методов
/// - Рекурсивных операций с деревьями
///
/// ## Производительность
///
/// Все операции выполняются за O(n) в один проход, используя collection-for.
/// Методы с поиском по значениям используют Set для O(1) проверки вхождения.
///
/// Все методы являются чистыми функциями (pure functions) - они не изменяют
/// исходный список, а возвращают новый с примененными изменениями.
///
class ListUpdater {
  const ListUpdater._();

  /// Обновляет элемент в списке по заданному значению
  ///
  /// [T] - тип элементов в списке
  /// [V] - тип значения для сопоставления (int, String, UUID, enum и т.д.)
  ///
  /// [items] - исходный список элементов
  /// [value] - значение для поиска элемента
  /// [valueExtractor] - функция извлечения значения из элемента
  /// [updater] - функция обновления элемента. Если возвращает null, элемент удаляется
  ///
  /// Edge cases:
  /// - Пустой список: возвращает `[]`
  /// - Значение не найдено: возвращает неизмененный список
  /// - updater возвращает null: элемент фильтруется (удаляется)
  ///
  /// Complexity: O(n) single-pass
  ///
  /// Пример:
  /// ```dart
  /// // Обновление по ID
  /// final updated = ListUpdater.updateBy<ChatMessageEntity, int>(
  ///   items: state.messages,
  ///   value: 123,
  ///   valueExtractor: (msg) => msg.id,
  ///   updater: (msg) => msg.copyWith(text: 'Updated'),
  /// );
  ///
  /// // Обновление по статусу (любое свойство!)
  /// final published = ListUpdater.updateBy<NoteEntity, NoteStatus>(
  ///   items: notes,
  ///   value: NoteStatus.draft,
  ///   valueExtractor: (n) => n.status,
  ///   updater: (n) => n.copyWith(status: NoteStatus.published),
  /// );
  ///
  /// // Удаление элемента (updater возвращает null)
  /// final deleted = ListUpdater.updateBy<FolderEntity, String>(
  ///   items: folders,
  ///   value: 'folder-123',
  ///   valueExtractor: (f) => f.uid,
  ///   updater: (_) => null,
  /// );
  /// ```
  static List<T> updateBy<T, V>({
    required List<T> items,
    required V value,
    required V Function(T) valueExtractor,
    required T? Function(T) updater,
  }) {
    return [
      for (final item in items)
        if (valueExtractor(item) == value) ?updater(item) else item,
    ];
  }

  /// Обновляет элементы в списке по условию (предикату)
  ///
  /// [T] - тип элементов в списке
  ///
  /// [items] - исходный список элементов
  /// [predicate] - условие для выбора элементов (возвращает true для элементов, которые нужно обновить)
  /// [updater] - функция обновления элемента. Если возвращает null, элемент удаляется
  ///
  /// Edge cases:
  /// - Пустой список: возвращает `[]`
  /// - Ни один элемент не соответствует: возвращает неизмененный список
  /// - updater возвращает null: элементы фильтруются (удаляются)
  ///
  /// Complexity: O(n) single-pass
  ///
  /// Пример:
  /// ```dart
  /// final updated = ListUpdater.updateWhere<ChatMessageEntity>(
  ///   items: state.messages,
  ///   predicate: (msg) => msg.isRead == false,
  ///   updater: (msg) => msg.copyWith(isRead: true),
  /// );
  ///
  /// // Массовое удаление по условию
  /// final cleaned = ListUpdater.updateWhere<NoteEntity>(
  ///   items: notes,
  ///   predicate: (n) => n.isEmpty,
  ///   updater: (_) => null, // Удалить все пустые заметки
  /// );
  /// ```
  static List<T> updateWhere<T>({
    required List<T> items,
    required bool Function(T) predicate,
    required T? Function(T) updater,
  }) {
    return [
      for (final item in items)
        if (predicate(item)) ?updater(item) else item,
    ];
  }

  /// Обновляет несколько элементов по набору значений
  ///
  /// [T] - тип элементов в списке
  /// [V] - тип значения для сопоставления
  ///
  /// [items] - исходный список элементов
  /// [values] - набор значений элементов для обновления
  /// [valueExtractor] - функция извлечения значения из элемента
  /// [updater] - функция обновления элемента. Если возвращает null, элемент удаляется
  ///
  /// Edge cases:
  /// - Пустой список: возвращает `[]`
  /// - Пустой набор values: возвращает неизмененный список
  /// - updater возвращает null: элементы фильтруются (удаляются)
  ///
  /// Complexity: O(n) с O(1) проверкой вхождения через Set
  ///
  /// Пример:
  /// ```dart
  /// final updated = ListUpdater.updateMany<ChatMessageEntity, int>(
  ///   items: state.messages,
  ///   values: {1, 2, 3},
  ///   valueExtractor: (msg) => msg.id,
  ///   updater: (msg) => msg.copyWith(isRead: true),
  /// );
  ///
  /// // Массовое удаление по набору ID
  /// final cleaned = ListUpdater.updateMany<FolderEntity, String>(
  ///   items: folders,
  ///   values: {'id1', 'id2', 'id3'},
  ///   valueExtractor: (f) => f.uid,
  ///   updater: (_) => null,
  /// );
  /// ```
  static List<T> updateMany<T, V>({
    required List<T> items,
    required Set<V> values,
    required V Function(T) valueExtractor,
    required T? Function(T) updater,
  }) {
    return [
      for (final item in items)
        if (values.contains(valueExtractor(item))) ?updater(item) else item,
    ];
  }

  /// Удаляет элемент из списка по заданному значению
  ///
  /// [T] - тип элементов в списке
  /// [V] - тип значения для сопоставления
  ///
  /// [items] - исходный список элементов
  /// [value] - значение для поиска элемента
  /// [valueExtractor] - функция извлечения значения из элемента
  ///
  /// Edge cases:
  /// - Пустой список: возвращает `[]`
  /// - Значение не найдено: возвращает неизмененный список
  ///
  /// Complexity: O(n)
  ///
  /// Пример:
  /// ```dart
  /// final updated = ListUpdater.removeBy<ChatMessageEntity, int>(
  ///   items: state.messages,
  ///   value: 123,
  ///   valueExtractor: (msg) => msg.id,
  /// );
  /// ```
  static List<T> removeBy<T, V>({
    required List<T> items,
    required V value,
    required V Function(T) valueExtractor,
  }) {
    return items.where((item) => valueExtractor(item) != value).toList();
  }

  /// Удаляет элементы из списка по условию
  ///
  /// [T] - тип элементов в списке
  ///
  /// [items] - исходный список элементов
  /// [predicate] - условие для удаления (возвращает true для элементов, которые нужно удалить)
  ///
  /// Edge cases:
  /// - Пустой список: возвращает `[]`
  /// - Ни один элемент не соответствует: возвращает неизмененный список
  ///
  /// Complexity: O(n)
  ///
  /// Пример:
  /// ```dart
  /// final updated = ListUpdater.removeWhere<ChatMessageEntity>(
  ///   items: state.messages,
  ///   predicate: (msg) => msg.isSystemMessage,
  /// );
  /// ```
  static List<T> removeWhere<T>({
    required List<T> items,
    required bool Function(T) predicate,
  }) {
    return items.where((item) => !predicate(item)).toList();
  }

  /// Заменяет существующий элемент или добавляет новый, если элемент не найден
  ///
  /// [T] - тип элементов в списке
  /// [V] - тип значения для сопоставления
  ///
  /// [items] - исходный список элементов
  /// [newItem] - новый элемент для замены/добавления
  /// [valueExtractor] - функция извлечения значения из элемента
  ///
  /// Edge cases:
  /// - Пустой список: добавляет `newItem`, возвращает `[newItem]`
  /// - Элемент не найден: добавляет в конец списка
  /// - Несколько совпадений: заменяет только первое вхождение
  ///
  /// Complexity: O(n)
  ///
  /// Пример:
  /// ```dart
  /// final updated = ListUpdater.replaceOrAdd<ChatMessageEntity, int>(
  ///   items: state.messages,
  ///   newItem: updatedMessage,
  ///   valueExtractor: (msg) => msg.id,
  /// );
  /// ```
  static List<T> replaceOrAdd<T, V>({
    required List<T> items,
    required T newItem,
    required V Function(T) valueExtractor,
  }) {
    final newItemId = valueExtractor(newItem);
    bool found = false;
    final result = <T>[];

    for (final item in items) {
      if (valueExtractor(item) == newItemId) {
        result.add(newItem);
        found = true;
      } else {
        result.add(item);
      }
    }

    // Если элемент не найден, добавляем в конец
    if (!found) result.add(newItem);

    return result;
  }

  /// Заменяет несколько элементов или добавляет новые
  ///
  /// [T] - тип элементов в списке
  /// [V] - тип значения для сопоставления
  ///
  /// [items] - исходный список элементов
  /// [newItems] - новые элементы для замены/добавления
  /// [valueExtractor] - функция извлечения значения из элемента
  ///
  /// Edge cases:
  /// - Пустой список items: добавляет все newItems, возвращает newItems
  /// - Пустой список newItems: возвращает неизмененный items
  /// - Дубликаты в newItems: последний в списке побеждает (поведение Map)
  ///
  /// Complexity: O(n + m) где n - размер items, m - размер newItems
  ///
  /// Пример:
  /// ```dart
  /// final updated = ListUpdater.replaceOrAddMultiple<ChatMessageEntity, int>(
  ///   items: state.messages,
  ///   newItems: [message1, message2],
  ///   valueExtractor: (msg) => msg.id,
  /// );
  /// ```
  static List<T> replaceOrAddMultiple<T, V>({
    required List<T> items,
    required List<T> newItems,
    required V Function(T) valueExtractor,
  }) {
    final newItemsMap = {
      for (final item in newItems) valueExtractor(item): item,
    };

    final result = <T>[];
    final processedIds = <V>{};

    // Заменяем существующие элементы
    for (final item in items) {
      final itemId = valueExtractor(item);
      final newItem = newItemsMap[itemId];

      if (newItem != null) {
        result.add(newItem);
        processedIds.add(itemId);
      } else {
        result.add(item);
      }
    }

    // Добавляем новые элементы, которые не были найдены
    for (final newItem in newItems) {
      final newItemId = valueExtractor(newItem);
      if (!processedIds.contains(newItemId)) result.add(newItem);
    }

    return result;
  }

  /// Вставляет элемент на указанную позицию
  ///
  /// [T] - тип элементов в списке
  ///
  /// [items] - исходный список элементов
  /// [index] - позиция для вставки
  /// [item] - элемент для вставки
  ///
  /// Edge cases:
  /// - Пустой список: вставляет элемент, возвращает `[item]`
  /// - index < 0: вставляет в начало (clamped to 0)
  /// - index > length: вставляет в конец (clamped to length)
  ///
  /// Complexity: O(n)
  ///
  /// Пример:
  /// ```dart
  /// final updated = ListUpdater.insertAt<ChatMessageEntity>(
  ///   items: state.messages,
  ///   index: 0,
  ///   item: newMessage,
  /// );
  /// ```
  static List<T> insertAt<T>({
    required List<T> items,
    required int index,
    required T item,
  }) {
    final result = [...items]..insert(index.clamp(0, items.length), item);
    return result;
  }

  /// Перемещает элемент с одной позиции на другую
  ///
  /// [T] - тип элементов в списке
  ///
  /// [items] - исходный список элементов
  /// [fromIndex] - начальная позиция
  /// [toIndex] - конечная позиция
  ///
  /// Edge cases:
  /// - Пустой список: возвращает `[]`
  /// - Индексы вне диапазона: возвращает неизмененный список
  /// - fromIndex == toIndex: возвращает неизмененный список
  ///
  /// Complexity: O(n)
  ///
  /// Пример:
  /// ```dart
  /// final updated = ListUpdater.move<ChatMessageEntity>(
  ///   items: state.messages,
  ///   fromIndex: 0,
  ///   toIndex: 5,
  /// );
  /// ```
  static List<T> move<T>({
    required List<T> items,
    required int fromIndex,
    required int toIndex,
  }) {
    if (fromIndex < 0 ||
        fromIndex >= items.length ||
        toIndex < 0 ||
        toIndex >= items.length) {
      return [...items];
    }

    final result = [...items];
    final item = result.removeAt(fromIndex);
    result.insert(toIndex, item);
    return result;
  }

  /// Рекурсивно обновляет элемент в древовидной структуре по заданному значению
  ///
  /// Этот метод предназначен для работы с древовидными структурами данных,
  /// где каждый элемент может содержать список дочерних элементов того же типа.
  ///
  /// [T] - тип элементов в дереве
  /// [V] - тип значения для сопоставления (int, String, UUID и т.д.)
  ///
  /// [items] - корневой список элементов дерева
  /// [value] - значение для поиска элемента
  /// [valueExtractor] - функция извлечения значения из элемента
  /// [childrenExtractor] - функция получения списка дочерних элементов из элемента
  /// [reconstruct] - функция реконструкции элемента с новым списком дочерних элементов.
  ///   Принимает исходный элемент и обновленный список детей, возвращает новый элемент
  /// [updater] - функция обновления элемента. Если возвращает null, элемент удаляется из дерева
  ///
  /// Edge cases:
  /// - Пустой список: возвращает `[]`
  /// - Значение не найдено: возвращает неизмененное дерево
  /// - updater возвращает null: элемент удаляется из дерева
  ///
  /// Complexity: O(n) где n - общее количество узлов в дереве
  ///
  /// Пример использования с комментариями:
  /// ```dart
  /// // Удаление комментария по ID
  /// final updated = ListUpdater.updateByRecursive<NewsCommentEntity, String>(
  ///   items: state.comments,
  ///   value: commentId,
  ///   valueExtractor: (c) => c.id,
  ///   childrenExtractor: (c) => c.subcomments,
  ///   reconstruct: (c, children) => c.copyWith(subcomments: children),
  ///   updater: (_) => null, // Возвращаем null для удаления
  /// );
  /// ```
  static List<T> updateByRecursive<T, V>({
    required List<T> items,
    required V value,
    required V Function(T) valueExtractor,
    required List<T> Function(T) childrenExtractor,
    required T Function(T item, List<T> updatedChildren) reconstruct,
    required T? Function(T) updater,
  }) {
    final result = <T>[];

    for (final item in items) {
      if (valueExtractor(item) == value) {
        // Нашли целевой элемент - применяем updater
        final updatedItem = updater(item);
        // Если updater вернул null, элемент удаляется (не добавляется в result)
        if (updatedItem != null) result.add(updatedItem);
      } else {
        // Элемент не совпал - рекурсивно обновляем его дочерние элементы
        final children = childrenExtractor(item);
        final updatedChildren = updateByRecursive<T, V>(
          items: children,
          value: value,
          valueExtractor: valueExtractor,
          childrenExtractor: childrenExtractor,
          reconstruct: reconstruct,
          updater: updater,
        );

        // Реконструируем элемент с обновленными детьми
        result.add(reconstruct(item, updatedChildren));
      }
    }

    return result;
  }
}

/// Extension methods для удобной работы со списками
///
/// Предоставляет те же операции, что и [ListUpdater], но с более эргономичным синтаксисом
/// и поддержкой метод-чейнинга.
///
/// Пример:
/// ```dart
/// final result = folders
///   .updateBy(value: uid, valueExtractor: (f) => f.uid, updater: (f) => ...)
///   .removeWhere((f) => f.notesCount == 0)
///   .upsert(item: newFolder, valueExtractor: (f) => f.uid);
/// ```
extension ListUpdateExtensions<T> on List<T> {
  /// См. [ListUpdater.updateBy]
  List<T> updateBy<V>({
    required V value,
    required V Function(T item) valueExtractor,
    required T? Function(T item) updater,
  }) => ListUpdater.updateBy(
    items: this,
    value: value,
    valueExtractor: valueExtractor,
    updater: updater,
  );

  /// См. [ListUpdater.updateWhere]
  List<T> updateWhere({
    required bool Function(T item) predicate,
    required T? Function(T item) updater,
  }) => ListUpdater.updateWhere(
    items: this,
    predicate: predicate,
    updater: updater,
  );

  /// См. [ListUpdater.updateMany]
  List<T> updateMany<V>({
    required Set<V> values,
    required V Function(T item) valueExtractor,
    required T? Function(T item) updater,
  }) => ListUpdater.updateMany(
    items: this,
    values: values,
    valueExtractor: valueExtractor,
    updater: updater,
  );

  /// См. [ListUpdater.removeBy]
  List<T> removeBy<V>({
    required V value,
    required V Function(T item) valueExtractor,
  }) => ListUpdater.removeBy(
    items: this,
    value: value,
    valueExtractor: valueExtractor,
  );

  /// См. [ListUpdater.removeWhere]
  List<T> removeWhere(bool Function(T item) predicate) =>
      ListUpdater.removeWhere(items: this, predicate: predicate);

  /// Alias для [ListUpdater.replaceOrAdd] - заменяет существующий элемент или добавляет новый
  ///
  /// См. [ListUpdater.replaceOrAdd]
  List<T> upsert<V>({
    required T item,
    required V Function(T item) valueExtractor,
  }) => ListUpdater.replaceOrAdd(
    items: this,
    newItem: item,
    valueExtractor: valueExtractor,
  );

  /// Alias для [ListUpdater.replaceOrAddMultiple] - заменяет/добавляет несколько элементов
  ///
  /// См. [ListUpdater.replaceOrAddMultiple]
  List<T> upsertMany<V>({
    required List<T> items,
    required V Function(T item) valueExtractor,
  }) => ListUpdater.replaceOrAddMultiple(
    items: this,
    newItems: items,
    valueExtractor: valueExtractor,
  );

  /// См. [ListUpdater.insertAt]
  List<T> insertAt({required int index, required T item}) =>
      ListUpdater.insertAt(items: this, index: index, item: item);

  /// См. [ListUpdater.move]
  List<T> move({required int fromIndex, required int toIndex}) =>
      ListUpdater.move(items: this, fromIndex: fromIndex, toIndex: toIndex);

  /// См. [ListUpdater.updateByRecursive]
  List<T> updateByRecursive<V>({
    required V value,
    required V Function(T item) valueExtractor,
    required List<T> Function(T children) childrenExtractor,
    required T Function(T item, List<T> updatedChildren) reconstruct,
    required T? Function(T item) updater,
  }) => ListUpdater.updateByRecursive(
    items: this,
    value: value,
    valueExtractor: valueExtractor,
    childrenExtractor: childrenExtractor,
    reconstruct: reconstruct,
    updater: updater,
  );
}
