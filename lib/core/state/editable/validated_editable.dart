import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/editable/editable.dart';

/// Результат валидации
class ValidationResult extends Equatable {
  /// Валидно ли значение?
  final bool isValid;

  /// Список ошибок (пустой если валидно)
  final List<String> errors;

  /// Результат успешной валидации
  const ValidationResult.valid() : isValid = true, errors = const [];

  /// Результат с ошибками
  const ValidationResult.invalid(this.errors) : isValid = false;

  /// Результат с одной ошибкой
  factory ValidationResult.error(String error) {
    return ValidationResult.invalid([error]);
  }

  /// Объединить несколько результатов
  ValidationResult merge(ValidationResult other) {
    if (isValid && other.isValid) return const ValidationResult.valid();

    return ValidationResult.invalid([...errors, ...other.errors]);
  }

  @override
  List<Object?> get props => [isValid, errors];

  @override
  String toString() =>
      isValid ? 'ValidationResult.valid' : 'ValidationResult.invalid($errors)';
}

/// Тип функции валидации
typedef Validator<T> = ValidationResult Function(T value);

/// Editable с поддержкой валидации.
///
/// Пример:
/// ```dart
/// final editable = ValidatedEditable.fromValue(
///   note,
///   validators: [
///     (note) => note.text.isEmpty
///         ? ValidationResult.error('Текст не может быть пустым')
///         : ValidationResult.valid(),
///   ],
/// );
///
/// print(editable.isValid); // true/false
/// print(editable.validationErrors); // список ошибок
/// ```
class ValidatedEditable<T extends Equatable> extends Equatable {
  /// Внутренний Editable
  final Editable<T> _editable;

  /// Список валидаторов
  final List<Validator<T>> validators;

  const ValidatedEditable._({
    required Editable<T> editable,
    required this.validators,
  }) : _editable = editable;

  /// Создать из значения
  factory ValidatedEditable.fromValue(
    T value, {
    List<Validator<T>> validators = const [],
  }) {
    return ValidatedEditable._(
      editable: Editable.fromValue(value),
      validators: validators,
    );
  }

  /// Создать из Editable
  factory ValidatedEditable.fromEditable(
    Editable<T> editable, {
    List<Validator<T>> validators = const [],
  }) {
    return ValidatedEditable._(editable: editable, validators: validators);
  }

  // ─────────────────────────────────────────────────────────────
  // Delegated getters
  // ─────────────────────────────────────────────────────────────

  T get original => _editable.original;

  T get current => _editable.current;

  T get value => _editable.value;

  bool get isEditing => _editable.isEditing;

  bool get hasChanges => _editable.hasChanges;

  bool get isClean => _editable.isClean;

  // ─────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────

  /// Выполнить валидацию текущего значения
  ValidationResult validate() {
    if (validators.isEmpty) return const ValidationResult.valid();

    ValidationResult result = const ValidationResult.valid();
    for (final validator in validators) {
      result = result.merge(validator(current));
    }

    return result;
  }

  /// Валидно ли текущее значение?
  bool get isValid => validate().isValid;

  /// Невалидно?
  bool get isInvalid => !isValid;

  /// Список ошибок валидации
  List<String> get validationErrors => validate().errors;

  /// Можно ли сохранить? (есть изменения И валидно)
  bool get canSave => hasChanges && isValid;

  // ─────────────────────────────────────────────────────────────
  // Mutations (сбрасывают кэш валидации)
  // ─────────────────────────────────────────────────────────────

  ValidatedEditable<T> _wrap(Editable<T> editable) {
    return ValidatedEditable._(editable: editable, validators: validators);
  }

  ValidatedEditable<T> startEditing() => _wrap(_editable.startEditing());

  ValidatedEditable<T> update(T newValue) => _wrap(_editable.update(newValue));

  ValidatedEditable<T> modify(T Function(T current) modifier) =>
      _wrap(_editable.modify(modifier));

  ValidatedEditable<T> commit() => _wrap(_editable.commit());

  ValidatedEditable<T> commitWith(T savedValue) =>
      _wrap(_editable.commitWith(savedValue));

  ValidatedEditable<T> revert() => _wrap(_editable.revert());

  ValidatedEditable<T> reset(T newOriginal) =>
      _wrap(_editable.reset(newOriginal));

  ValidatedEditable<T> cancelEditing() => _wrap(_editable.cancelEditing());

  /// Получить внутренний Editable
  Editable<T> toEditable() => _editable;

  /// Добавить валидатор
  ValidatedEditable<T> addValidator(Validator<T> validator) {
    return ValidatedEditable._(
      editable: _editable,
      validators: [...validators, validator],
    );
  }

  /// Заменить валидаторы
  ValidatedEditable<T> withValidators(List<Validator<T>> newValidators) {
    return ValidatedEditable._(editable: _editable, validators: newValidators);
  }

  // ─────────────────────────────────────────────────────────────
  // Equatable
  // ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [_editable, validators];

  @override
  String toString() =>
      'ValidatedEditable(isEditing: $isEditing, hasChanges: $hasChanges, '
      'isValid: $isValid)';
}

// ─────────────────────────────────────────────────────────────
// Common validators
// ─────────────────────────────────────────────────────────────

/// Набор готовых валидаторов
class Validators {
  Validators._();

  /// Строка не пустая
  static ValidationResult notEmpty(String value) {
    return value.trim().isEmpty
        ? ValidationResult.error('Поле не может быть пустым')
        : const ValidationResult.valid();
  }

  /// Минимальная длина строки
  static Validator<String> minLength(int length, {String? message}) {
    return (value) => value.length < length
        ? ValidationResult.error(message ?? 'Минимум $length символов')
        : const ValidationResult.valid();
  }

  /// Максимальная длина строки
  static Validator<String> maxLength(int length, {String? message}) {
    return (value) => value.length > length
        ? ValidationResult.error(message ?? 'Максимум $length символов')
        : const ValidationResult.valid();
  }

  /// Значение не null
  static ValidationResult notNull<T>(T? value) {
    return value == null
        ? ValidationResult.error('Значение обязательно')
        : const ValidationResult.valid();
  }

  /// Кастомный валидатор
  static Validator<T> custom<T>(
    bool Function(T value) predicate,
    String errorMessage,
  ) {
    return (value) => predicate(value)
        ? const ValidationResult.valid()
        : ValidationResult.error(errorMessage);
  }
}
