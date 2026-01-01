import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_state.dart';
import 'package:voice_notes/core/state/initializable.dart';

/// Базовый кубит с удобными методами для работы с BaseState
abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  BaseCubit([BaseState<T>? initialState])
    : super(initialState ?? const BaseState.initial()) {
    if (this is Initializable) (this as Initializable).init();
  }

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
  void withData(void Function(T data) action) {
    final data = state.dataOrNull;
    if (data != null) action(data);
  }

  /// Async версия [withData].
  Future<void> withDataAsync(Future<void> Function(T data) action) async {
    final data = state.dataOrNull;
    if (data != null) await action(data);
  }

  // ═══════════════════════════════════════════════════════════════════
  // State transformation
  // ═══════════════════════════════════════════════════════════════════

  /// Выполнить действие с автоматическим управлением состояниями
  ///
  /// Loading → Success/Error
  Future<void> guard(FutureOr<T> Function() action) async {
    emitLoading();
    await safeExecute(
      action: () async => emitSuccess(await action()),
      onError: emitError,
    );
  }

  /// Трансформировать данные с обработкой ошибок.
  /// При ошибке emitError, иначе emitSuccess.
  Future<void> tryUpdate(FutureOr<T> Function(T current) updater) async {
    final data = state.dataOrNull;
    if (data == null) return;

    await safeExecute(
      action: () async => emitSuccess(await updater(data)),
      onError: emitError,
    );
  }

  /// Трансформировать данные и emit Success (sync).
  /// Ничего не делает, если состояние не Success.
  void update(T Function(T current) updater) {
    final data = state.dataOrNull;
    if (data != null) emitSuccess(updater(data));
  }

  /// Трансформировать данные и emit Success (async).
  /// Ничего не делает, если состояние не Success.
  Future<void> updateAsync(Future<T> Function(T current) updater) async {
    final data = state.dataOrNull;
    if (data != null) emitSuccess(await updater(data));
  }

  /// Выполнить действие без смены состояния
  ///
  /// Ошибки логируются через addError, но состояние не меняется.
  /// Используй для фоновых операций, где не нужно показывать ошибку в UI.
  Future<void> safeExecute({
    required FutureOr<void> Function() action,
    void Function(AppFailure failure)? onError,
  }) async {
    try {
      await action();
    } catch (e, s) {
      addError(e, s);

      final failure = AppFailure.from(e, s);
      onError?.call(failure);
    }
  }

  /// Выполнить действие и вернуть результат или null
  Future<R?> safeExecuteResult<R>({
    required Future<R> Function() action,
    void Function(AppFailure failure)? onError,
  }) async {
    try {
      return await action();
    } catch (e, s) {
      addError(e, s);

      final failure = AppFailure.from(e, s);
      onError?.call(failure);

      return null;
    }
  }
}
