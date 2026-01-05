import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/editable/editable.dart';

/// Editable с поддержкой истории изменений (Undo/Redo).
///
/// В отличие от базового [Editable], хранит историю всех изменений
/// и позволяет перемещаться по ней.
///
/// Пример:
/// ```dart
/// var editable = EditableWithHistory.fromValue(note);
/// editable = editable.modify((n) => n.copyWith(text: 'v1'));
/// editable = editable.modify((n) => n.copyWith(text: 'v2'));
/// print(editable.canUndo); // true
/// editable = editable.undo();
/// print(editable.current.text); // 'v1'
/// editable = editable.redo();
/// print(editable.current.text); // 'v2'
/// ```
class EditableWithHistory<T extends Equatable> extends Equatable {
  /// История значений (от старых к новым)
  final List<T> _history;

  /// Текущий индекс в истории
  final int _historyIndex;

  /// Начальное значение (snapshot до редактирования)
  final T original;

  /// Флаг режима редактирования
  final bool isEditing;

  /// Максимальный размер истории (0 = без ограничений)
  final int maxHistorySize;

  const EditableWithHistory._({
    required List<T> history,
    required int historyIndex,
    required this.original,
    required this.isEditing,
    this.maxHistorySize = 50,
  }) : _history = history,
       _historyIndex = historyIndex;

  /// Создать из начального значения
  factory EditableWithHistory.fromValue(T value, {int maxHistorySize = 50}) {
    return EditableWithHistory._(
      history: [value],
      historyIndex: 0,
      original: value,
      isEditing: false,
      maxHistorySize: maxHistorySize,
    );
  }

  /// Создать из обычного Editable
  factory EditableWithHistory.fromEditable(
    Editable<T> editable, {
    int maxHistorySize = 50,
  }) {
    return EditableWithHistory._(
      history: [editable.current],
      historyIndex: 0,
      original: editable.original,
      isEditing: editable.isEditing,
      maxHistorySize: maxHistorySize,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────

  /// Текущее значение
  T get current => _history[_historyIndex];

  /// Значение для отображения (alias для current)
  T get value => current;

  /// Есть ли изменения относительно оригинала?
  bool get hasChanges => original != current;

  /// Нет изменений?
  bool get isClean => !hasChanges;

  /// Можно ли откатить назад?
  bool get canUndo => _historyIndex > 0;

  /// Можно ли вернуть вперёд?
  bool get canRedo => _historyIndex < _history.length - 1;

  /// Количество шагов назад
  int get undoCount => _historyIndex;

  /// Количество шагов вперёд
  int get redoCount => _history.length - 1 - _historyIndex;

  /// Размер истории
  int get historySize => _history.length;

  // ─────────────────────────────────────────────────────────────
  // Mutations
  // ─────────────────────────────────────────────────────────────

  /// Начать редактирование
  EditableWithHistory<T> startEditing() {
    return EditableWithHistory._(
      history: [current],
      historyIndex: 0,
      original: current,
      isEditing: true,
      maxHistorySize: maxHistorySize,
    );
  }

  /// Обновить текущее значение (добавить в историю)
  EditableWithHistory<T> update(T newValue) {
    if (newValue == current) return this;

    // Обрезать историю после текущего индекса
    final newHistory = _history.sublist(0, _historyIndex + 1).toList()
      ..add(newValue);

    // Ограничить размер истории
    final trimmedHistory =
        maxHistorySize > 0 && newHistory.length > maxHistorySize
        ? newHistory.sublist(newHistory.length - maxHistorySize)
        : newHistory;

    final newIndex = trimmedHistory.length - 1;

    return EditableWithHistory._(
      history: trimmedHistory,
      historyIndex: newIndex,
      original: original,
      isEditing: isEditing,
      maxHistorySize: maxHistorySize,
    );
  }

  /// Обновить через функцию
  EditableWithHistory<T> modify(T Function(T current) modifier) {
    return update(modifier(current));
  }

  /// Откатить на шаг назад
  EditableWithHistory<T> undo() {
    if (!canUndo) return this;

    return EditableWithHistory._(
      history: _history,
      historyIndex: _historyIndex - 1,
      original: original,
      isEditing: isEditing,
      maxHistorySize: maxHistorySize,
    );
  }

  /// Вернуть на шаг вперёд
  EditableWithHistory<T> redo() {
    if (!canRedo) return this;

    return EditableWithHistory._(
      history: _history,
      historyIndex: _historyIndex + 1,
      original: original,
      isEditing: isEditing,
      maxHistorySize: maxHistorySize,
    );
  }

  /// Зафиксировать изменения
  EditableWithHistory<T> commit() {
    return EditableWithHistory._(
      history: [current],
      historyIndex: 0,
      original: current,
      isEditing: false,
      maxHistorySize: maxHistorySize,
    );
  }

  /// Зафиксировать с новым значением
  EditableWithHistory<T> commitWith(T savedValue) {
    return EditableWithHistory._(
      history: [savedValue],
      historyIndex: 0,
      original: savedValue,
      isEditing: false,
      maxHistorySize: maxHistorySize,
    );
  }

  /// Откатить к оригиналу
  EditableWithHistory<T> revert() {
    return EditableWithHistory._(
      history: [original],
      historyIndex: 0,
      original: original,
      isEditing: false,
      maxHistorySize: maxHistorySize,
    );
  }

  /// Сбросить к новому значению
  EditableWithHistory<T> reset(T newOriginal) {
    return EditableWithHistory._(
      history: [newOriginal],
      historyIndex: 0,
      original: newOriginal,
      isEditing: false,
      maxHistorySize: maxHistorySize,
    );
  }

  /// Отменить редактирование
  EditableWithHistory<T> cancelEditing() => revert();

  /// Конвертировать в обычный Editable (без истории)
  Editable<T> toEditable() {
    return Editable.internal(
      original: original,
      current: current,
      isEditing: isEditing,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Equatable
  // ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [_history, _historyIndex, original, isEditing];

  @override
  String toString() =>
      'EditableWithHistory(isEditing: $isEditing, hasChanges: $hasChanges, '
      'undoCount: $undoCount, redoCount: $redoCount)';
}
