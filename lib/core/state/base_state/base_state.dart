import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_failure.dart';

/// Базовое состояние для Cubit/BLoC с 4 вариантами: Initial, Loading, Success, Error
sealed class BaseState<T> extends Equatable {
  const BaseState();

  const factory BaseState.initial() = InitialState<T>;

  const factory BaseState.loading() = LoadingState<T>;

  const factory BaseState.success(T data) = SuccessState<T>;

  const factory BaseState.error(AppFailure failure) = ErrorState<T>;

  @override
  List<Object?> get props => [];
}

final class InitialState<T> extends BaseState<T> {
  const InitialState();
}

final class LoadingState<T> extends BaseState<T> {
  const LoadingState();
}

final class SuccessState<T> extends BaseState<T> {
  final T data;

  const SuccessState(this.data);

  @override
  List<Object?> get props => [data];
}

final class ErrorState<T> extends BaseState<T> {
  final AppFailure failure;

  const ErrorState(this.failure);

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}

extension BaseStateX<T> on BaseState<T> {
  bool get isInitial => this is InitialState<T>;

  bool get isLoading => this is LoadingState<T>;

  bool get isSuccess => this is SuccessState<T>;

  bool get isError => this is ErrorState<T>;

  T? get dataOrNull => switch (this) {
    SuccessState(:final data) => data,
    _ => null,
  };

  // Throws StateError если не Success
  T get requireData => switch (this) {
    SuccessState(:final data) => data,
    _ => throw StateError('Expected Success state, got $runtimeType'),
  };

  AppFailure? get failureOrNull => switch (this) {
    ErrorState(:final failure) => failure,
    _ => null,
  };

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(AppFailure failure) error,
  }) => switch (this) {
    InitialState() => initial(),
    LoadingState() => loading(),
    SuccessState(:final data) => success(data),
    ErrorState(:final failure) => error(failure),
  };

  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(AppFailure failure)? error,
  }) => switch (this) {
    InitialState() => initial?.call() ?? orElse(),
    LoadingState() => loading?.call() ?? orElse(),
    SuccessState(:final data) => success?.call(data) ?? orElse(),
    ErrorState(:final failure) => error?.call(failure) ?? orElse(),
  };

  R? whenOrNull<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(AppFailure failure)? error,
  }) {
    return switch (this) {
      InitialState() => initial?.call(),
      LoadingState() => loading?.call(),
      SuccessState(:final data) => success?.call(data),
      ErrorState(:final failure) => error?.call(failure),
    };
  }
}
