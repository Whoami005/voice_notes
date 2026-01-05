import 'package:equatable/equatable.dart';

/// Обёртка для отслеживания изменений Equatable-объекта.
///
/// Хранит [original] (snapshot до редактирования) и [current] (текущее значение).
/// Позволяет обнаруживать изменения без обращения к БД.
///
/// [T] должен наследоваться от Equatable для корректного сравнения.
///
/// Пример:
/// ```dart
/// final editable = Editable.fromValue(note);
/// final editing = editable.startEditing();
/// final modified = editing.modify((n) => n.copyWith(text: 'new'));
/// print(modified.hasChanges); // true
/// final saved = modified.commitWith(savedNote);
/// ```
class Editable<T extends Equatable> extends Equatable {
  /// Начальное значение (snapshot до редактирования)
  final T original;

  /// Текущее значение (может быть изменено)
  final T current;

  /// Флаг режима редактирования
  final bool isEditing;

  const Editable.internal({
    required this.original,
    required this.current,
    required this.isEditing,
  });

  /// Создать из начального значения (original = current, isEditing = false)
  const Editable.fromValue(T value)
      : original = value,
        current = value,
        isEditing = false;

  // ─────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────

  /// Есть ли изменения относительно оригинала?
  bool get hasChanges => original != current;

  /// Нет изменений?
  bool get isClean => !hasChanges;

  /// Значение для отображения (current)
  T get value => current;

  // ─────────────────────────────────────────────────────────────
  // Mutations (возвращают новый Editable)
  // ─────────────────────────────────────────────────────────────

  /// Начать редактирование (зафиксировать current как snapshot)
  Editable<T> startEditing() {
    return Editable.internal(
      original: current,
      current: current,
      isEditing: true,
    );
  }

  /// Обновить текущее значение
  Editable<T> update(T newValue) {
    return Editable.internal(
      original: original,
      current: newValue,
      isEditing: isEditing,
    );
  }

  /// Обновить текущее значение через функцию (удобно для copyWith)
  Editable<T> modify(T Function(T current) modifier) {
    return update(modifier(current));
  }

  /// Зафиксировать изменения (original = current, выход из режима редактирования)
  Editable<T> commit() {
    return Editable.internal(
      original: current,
      current: current,
      isEditing: false,
    );
  }

  /// Зафиксировать с новым значением (после успешного сохранения в БД)
  Editable<T> commitWith(T savedValue) {
    return Editable.internal(
      original: savedValue,
      current: savedValue,
      isEditing: false,
    );
  }

  /// Откатить изменения (current = original, выход из редактирования)
  Editable<T> revert() {
    return Editable.internal(
      original: original,
      current: original,
      isEditing: false,
    );
  }

  /// Сбросить к новому значению (например, после загрузки из БД)
  Editable<T> reset(T newOriginal) {
    return Editable.internal(
      original: newOriginal,
      current: newOriginal,
      isEditing: false,
    );
  }

  /// Выйти из режима редактирования без сохранения (эквивалент revert)
  Editable<T> cancelEditing() => revert();

  // ─────────────────────────────────────────────────────────────
  // Equatable
  // ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [original, current, isEditing];

  @override
  String toString() =>
      'Editable(isEditing: $isEditing, hasChanges: $hasChanges)';
}
