import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_failure.dart';

/// Статус жизненного цикла: init, loading, success, error
enum LogicStateStatus {
  /// Начальное состояние (до первой загрузки)
  init,

  /// Загрузка данных
  loading,

  /// Успешная загрузка
  success,

  /// Ошибка
  error;

  bool get isInit => this == LogicStateStatus.init;

  bool get isLoading => this == LogicStateStatus.loading;

  bool get isSuccess => this == LogicStateStatus.success;

  bool get isError => this == LogicStateStatus.error;
}

/// Базовое состояние с enum статусом (все данные в одном классе).
abstract class StatusState extends Equatable {
  /// Статус жизненного цикла
  final LogicStateStatus status;

  /// Ошибка
  final AppFailure? failure;

  const StatusState({this.status = LogicStateStatus.init, this.failure});

  /// Обязательный copyWith для изменения состояния
  StatusState copyWith({LogicStateStatus? status, AppFailure? failure});

  @override
  List<Object?> get props => [status, failure];
}

/// Хелперы для удобной работы с StatusState
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
      LogicStateStatus.init => init(),
      LogicStateStatus.loading => loading(),
      LogicStateStatus.success => success(),
      LogicStateStatus.error => error(failure),
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
      LogicStateStatus.init => init?.call() ?? orElse(),
      LogicStateStatus.loading => loading?.call() ?? orElse(),
      LogicStateStatus.success => success?.call() ?? orElse(),
      LogicStateStatus.error => error?.call(failure) ?? orElse(),
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
      LogicStateStatus.init => init?.call(),
      LogicStateStatus.loading => loading?.call(),
      LogicStateStatus.success => success?.call(),
      LogicStateStatus.error => error?.call(failure),
    };
  }
}
