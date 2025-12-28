import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_failure.dart';

/// Базовое состояние для Cubit/BLoC
///
/// Пример использования:
/// ```dart
/// class FoldersCubit extends Cubit<BaseState<List<Folder>>> {
///   FoldersCubit() : super(const Initial());
/// }
/// ```
sealed class BaseState<T> extends Equatable {
  const BaseState();

  const factory BaseState.initial() = InitialState<T>;

  const factory BaseState.loading() = LoadingState<T>;

  const factory BaseState.success(T data) = SuccessState<T>;

  const factory BaseState.error(AppFailure failure) = ErrorState<T>;

  @override
  List<Object?> get props => [];
}

/// Начальное состояние (до первой загрузки)
final class InitialState<T> extends BaseState<T> {
  const InitialState();
}

/// Состояние загрузки
final class LoadingState<T> extends BaseState<T> {
  const LoadingState();
}

/// Успешная загрузка данных
final class SuccessState<T> extends BaseState<T> {
  final T data;

  const SuccessState(this.data);

  @override
  List<Object?> get props => [data];
}

/// Ошибка с AppFailure
final class ErrorState<T> extends BaseState<T> {
  final AppFailure failure;

  const ErrorState(this.failure);

  /// Сообщение ошибки для UI
  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}

/// Хелперы для удобной работы с состояниями
extension BaseStateX<T> on BaseState<T> {
  bool get isInitial => this is InitialState<T>;

  bool get isLoading => this is LoadingState<T>;

  bool get isSuccess => this is SuccessState<T>;

  bool get isError => this is ErrorState<T>;

  /// Данные или null
  T? get dataOrNull => switch (this) {
    SuccessState(:final data) => data,
    _ => null,
  };

  /// Данные напрямую (выбрасывает StateError если не Success)
  ///
  /// Использовать когда состояние гарантированно Success:
  /// - в методах кубита после успешной загрузки
  /// - в UI внутри Success-ветки
  T get requireData => switch (this) {
    SuccessState(:final data) => data,
    _ => throw StateError('Expected Success state, got $runtimeType'),
  };

  /// Ошибка или null
  AppFailure? get failureOrNull => switch (this) {
    ErrorState(:final failure) => failure,
    _ => null,
  };

  /// Pattern matching с обязательными колбэками
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

  /// Pattern matching с fallback
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
}
