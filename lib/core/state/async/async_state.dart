import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/status/status_state.dart';

/// Состояние для асинхронных операций: Initial → Loading → Success/Error.
///
/// Используй когда:
/// - Данные загружаются асинхронно
/// - Нужны чёткие состояния жизненного цикла
/// - Не требуется хранить данные между состояниями
///
/// Для сохранения данных между состояниями используй [StatusState].
sealed class AsyncState<T> extends Equatable {
  const AsyncState();

  const factory AsyncState.initial() = AsyncInitial<T>;

  const factory AsyncState.loading() = AsyncLoading<T>;

  const factory AsyncState.success(T data) = AsyncSuccess<T>;

  const factory AsyncState.error(AppFailure failure) = AsyncError<T>;

  @override
  List<Object?> get props => [];
}

/// Начальное состояние (до загрузки)
final class AsyncInitial<T> extends AsyncState<T> {
  const AsyncInitial();
}

/// Состояние загрузки
final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

/// Успешное состояние с данными
final class AsyncSuccess<T> extends AsyncState<T> {
  final T data;

  const AsyncSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

/// Состояние ошибки
final class AsyncError<T> extends AsyncState<T> {
  final AppFailure failure;

  const AsyncError(this.failure);

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}

/// Extension-методы для удобной работы с [AsyncState]
extension AsyncStateX<T> on AsyncState<T> {
  bool get isInitial => this is AsyncInitial<T>;

  bool get isLoading => this is AsyncLoading<T>;

  bool get isSuccess => this is AsyncSuccess<T>;

  bool get isError => this is AsyncError<T>;

  /// Данные или null
  T? get dataOrNull => switch (this) {
    AsyncSuccess(:final data) => data,
    _ => null,
  };

  /// Данные или исключение
  T get requireData => switch (this) {
    AsyncSuccess(:final data) => data,
    _ => throw StateError('Expected AsyncSuccess, got $runtimeType'),
  };

  /// Ошибка или null
  AppFailure? get failureOrNull => switch (this) {
    AsyncError(:final failure) => failure,
    _ => null,
  };

  /// Pattern matching с обязательными колбэками
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(AppFailure failure) error,
  }) => switch (this) {
    AsyncInitial() => initial(),
    AsyncLoading() => loading(),
    AsyncSuccess(:final data) => success(data),
    AsyncError(:final failure) => error(failure),
  };

  /// Pattern matching с fallback
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(AppFailure failure)? error,
  }) => switch (this) {
    AsyncInitial() => initial?.call() ?? orElse(),
    AsyncLoading() => loading?.call() ?? orElse(),
    AsyncSuccess(:final data) => success?.call(data) ?? orElse(),
    AsyncError(:final failure) => error?.call(failure) ?? orElse(),
  };

  /// Pattern matching с возможностью вернуть null
  R? whenOrNull<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(AppFailure failure)? error,
  }) {
    return switch (this) {
      AsyncInitial() => initial?.call(),
      AsyncLoading() => loading?.call(),
      AsyncSuccess(:final data) => success?.call(data),
      AsyncError(:final failure) => error?.call(failure),
    };
  }
}
