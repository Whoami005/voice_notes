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

  const factory BaseState.initial() = Initial<T>;

  const factory BaseState.loading() = Loading<T>;

  const factory BaseState.success(T data) = Success<T>;

  const factory BaseState.error(AppFailure failure) = Error<T>;

  @override
  List<Object?> get props => [];
}

/// Начальное состояние (до первой загрузки)
final class Initial<T> extends BaseState<T> {
  const Initial();
}

/// Состояние загрузки
final class Loading<T> extends BaseState<T> {
  const Loading();
}

/// Успешная загрузка данных
final class Success<T> extends BaseState<T> {
  final T data;

  const Success(this.data);

  @override
  List<Object?> get props => [data];
}

/// Ошибка с AppFailure
final class Error<T> extends BaseState<T> {
  final AppFailure failure;

  const Error(this.failure);

  /// Сообщение ошибки для UI
  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}

/// Хелперы для удобной работы с состояниями
extension BaseStateX<T> on BaseState<T> {
  bool get isInitial => this is Initial<T>;

  bool get isLoading => this is Loading<T>;

  bool get isSuccess => this is Success<T>;

  bool get isError => this is Error<T>;

  /// Данные или null
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    _ => null,
  };

  /// Данные напрямую (выбрасывает StateError если не Success)
  ///
  /// Использовать когда состояние гарантированно Success:
  /// - в методах кубита после успешной загрузки
  /// - в UI внутри Success-ветки
  T get requireData => switch (this) {
    Success(:final data) => data,
    _ => throw StateError('Expected Success state, got $runtimeType'),
  };

  /// Ошибка или null
  AppFailure? get failureOrNull => switch (this) {
    Error(:final failure) => failure,
    _ => null,
  };

  /// Pattern matching с обязательными колбэками
  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(AppFailure failure) error,
  }) => switch (this) {
    Initial() => initial(),
    Loading() => loading(),
    Success(:final data) => success(data),
    Error(:final failure) => error(failure),
  };

  /// Pattern matching с fallback
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(AppFailure failure)? error,
  }) => switch (this) {
    Initial() => initial?.call() ?? orElse(),
    Loading() => loading?.call() ?? orElse(),
    Success(:final data) => success?.call(data) ?? orElse(),
    Error(:final failure) => error?.call(failure) ?? orElse(),
  };
}
