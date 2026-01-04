import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_state/base_state.dart';

/// Базовый кубит для работы с BaseState.
///
/// Основные методы: load/guard (Loading→Success/Error), transform/modify (трансформация данных)
abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  BaseCubit([BaseState<T>? initialState])
    : super(initialState ?? const BaseState.initial());

  T? get dataOrNull => state.dataOrNull;

  T get requireData => state.requireData;

  void emitInitial() => emit(const BaseState.initial());

  void emitLoading() => emit(const BaseState.loading());

  void emitSuccess(T data) => emit(BaseState.success(data));

  void emitError(AppFailure failure) => emit(BaseState.error(failure));

  // Выполнить действие с текущими данными (ничего не делает если не Success)
  FutureOr<R?> whenData<R>(FutureOr<R> Function(T data) action) {
    final data = state.dataOrNull;
    if (data == null) return null;

    return action(data);
  }

  // Loading → Success/Error (для начальной загрузки)
  Future<void> load(FutureOr<T> Function() action) async {
    emitLoading();
    await execute(
      action: () async => emitSuccess(await action()),
      onError: emitError,
    );
  }

  FutureOr<void> guard(
    FutureOr<T> Function() future, {
    void Function(AppFailure failure)? onError,
  }) async {
    try {
      emitSuccess(await future());
    } catch (e, s) {
      final failure = logError(e, s);
      onError != null ? onError(failure) : emitError(failure);
    }
  }

  FutureOr<void> transform(
    FutureOr<T> Function(T current) transformer, {
    void Function(AppFailure failure)? onError,
  }) async {
    final data = state.dataOrNull;
    if (data == null) return;

    try {
      emitSuccess(await transformer(data));
    } catch (e, s) {
      final failure = logError(e, s);
      onError?.call(failure);
    }
  }

  FutureOr<R?> modify<R>(
    FutureOr<R> Function(T current) modifier, {
    R Function(AppFailure failure)? onError,
  }) async {
    final data = state.dataOrNull;
    if (data == null) return null;

    try {
      return await modifier(data);
    } catch (e, s) {
      final failure = logError(e, s);
      return onError?.call(failure);
    }
  }

  StreamSubscription<T> watchStream(
    Stream<T> stream, {
    void Function(AppFailure)? onError,
  }) {
    return stream.listen(
      emitSuccess,
      cancelOnError: false,
      onError: (Object e, StackTrace s) {
        final failure = logError(e, s);
        onError?.call(failure);
      },
    );
  }

  // Выполнить действие без смены состояния (для фоновых операций)
  FutureOr<void> execute({
    required FutureOr<void> Function() action,
    void Function(AppFailure failure)? onError,
  }) async {
    try {
      await action();
    } catch (e, s) {
      final failure = logError(e, s);
      onError?.call(failure);
    }
  }

  AppFailure logError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);

    return AppFailure.from(error, stackTrace);
  }
}
