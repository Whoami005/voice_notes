import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_failure.dart';

/// Статус жизненного цикла: init, loading, success, error.
enum Status {
  /// Начальное состояние (до первой загрузки)
  init,

  /// Загрузка данных
  loading,

  /// Успешная загрузка
  success,

  /// Ошибка
  error;

  bool get isInit => this == Status.init;

  bool get isLoading => this == Status.loading;

  bool get isSuccess => this == Status.success;

  bool get isError => this == Status.error;
}

/// Базовое состояние с enum статусом (все данные в одном классе).
///
/// Используй когда:
/// - Нужно хранить много полей в состоянии
/// - Данные должны сохраняться между loading/error
/// - Требуется частичное обновление данных
abstract class StatusState extends Equatable {
  /// Статус жизненного цикла
  final Status status;

  /// Ошибка
  final AppFailure? failure;

  const StatusState({this.status = Status.init, this.failure});

  /// Обязательный copyWith для изменения состояния
  StatusState copyWith({Status? status, AppFailure? failure});

  @override
  List<Object?> get props => [status, failure];
}

/// Extension-методы для удобной работы с [StatusState]
extension StatusStateX on StatusState {
  bool get isInit => status.isInit;

  bool get isLoading => status.isLoading;

  bool get isSuccess => status.isSuccess;

  bool get isError => status.isError;

  /// Есть ли ошибка
  bool get hasFailure => failure != null;

  /// Сообщение ошибки для UI
  String get errorMessage => failure?.message ?? '';

  /// Pattern matching с обязательными колбэками
  R when<R>({
    required R Function() init,
    required R Function() loading,
    required R Function() success,
    required R Function(AppFailure? failure) error,
  }) {
    return switch (status) {
      Status.init => init(),
      Status.loading => loading(),
      Status.success => success(),
      Status.error => error(failure),
    };
  }

  /// Pattern matching с fallback
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? init,
    R Function()? loading,
    R Function()? success,
    R Function(AppFailure? failure)? error,
  }) {
    return switch (status) {
      Status.init => init?.call() ?? orElse(),
      Status.loading => loading?.call() ?? orElse(),
      Status.success => success?.call() ?? orElse(),
      Status.error => error?.call(failure) ?? orElse(),
    };
  }

  /// Pattern matching с возможностью вернуть null
  R? whenOrNull<R>({
    R Function()? init,
    R Function()? loading,
    R Function()? success,
    R Function(AppFailure? failure)? error,
  }) {
    return switch (status) {
      Status.init => init?.call(),
      Status.loading => loading?.call(),
      Status.success => success?.call(),
      Status.error => error?.call(failure),
    };
  }
}
