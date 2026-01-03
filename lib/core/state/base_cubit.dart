import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_state.dart';

/// Базовый кубит с удобными методами для работы с BaseState.
///
/// ## Группы методов
///
/// - **emit*** — прямая отправка состояния
/// - **guard** — полный цикл Loading → Success/Error
/// - **update** — трансформация без error handling
/// - **updateSafe** — трансформация с error handling
/// - **safeExecute** — фоновые операции без изменения UI
/// - **withData** — работа с данными + ручной emit
abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  BaseCubit([BaseState<T>? initialState])
    : super(initialState ?? const BaseState.initial());

  // ═══════════════════════════════════════════════════════════════════
  // Data helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Текущие данные или null
  T? get dataOrNull => state.dataOrNull;

  /// Текущие данные (throws если не Success)
  T get requireData => state.requireData;

  // ═══════════════════════════════════════════════════════════════════
  // Convenience emitters
  // ═══════════════════════════════════════════════════════════════════

  void emitInitial() => emit(const BaseState.initial());

  void emitLoading() => emit(const BaseState.loading());

  void emitSuccess(T data) => emit(BaseState.success(data));

  void emitError(AppFailure failure) => emit(BaseState.error(failure));

  // ═══════════════════════════════════════════════════════════════════
  // Data access with guaranteed non-null
  // ═══════════════════════════════════════════════════════════════════

  /// Выполнить действие с текущими данными (гарантированно не null).
  /// Ничего не делает, если состояние не Success.
  /// Поддерживает sync и async.
  FutureOr<R?> whenData<R>(FutureOr<R> Function(T data) action) {
    final data = state.dataOrNull;
    if (data == null) return null;

    return action(data);
  }

  // ═══════════════════════════════════════════════════════════════════
  // State transformation
  // ═══════════════════════════════════════════════════════════════════

  /// Выполнить действие с автоматическим управлением состояниями.
  ///
  /// Loading → Success/Error.
  /// Используй для начальной загрузки данных (init).
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

  /// Трансформировать данные и emit Success.
  ///
  /// Ничего не делает, если состояние не Success.
  /// Без обработки ошибок — используй для безопасных операций.
  /// Поддерживает sync и async.
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

  /// Выполнить действие без смены состояния.
  ///
  /// Ошибки логируются через addError, но состояние не меняется.
  /// Используй для фоновых операций, где не нужно показывать ошибку в UI.
  /// Поддерживает sync и async.
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
