import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_state.dart';

/// Базовый кубит с удобными методами для работы с BaseState
abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  BaseCubit([BaseState<T>? initialState])
    : super(initialState ?? const BaseState.initial());

  // ═══════════════════════════════════════════════════════════════════
  // Convenience emitters
  // ═══════════════════════════════════════════════════════════════════

  void emitInitial() => emit(const BaseState.initial());

  void emitLoading() => emit(const BaseState.loading());

  void emitSuccess(T data) => emit(BaseState.success(data));

  void emitError(AppFailure failure) => emit(BaseState.error(failure));

  // ═══════════════════════════════════════════════════════════════════
  // Data helpers
  // ═══════════════════════════════════════════════════════════════════

  /// Текущие данные или null
  T? get dataOrNull => state.dataOrNull;

  /// Текущие данные (throws если не Success)
  T get requireData => state.requireData;

  /// Обновить данные в Success состоянии
  void updateData(T Function(T current) updater) {
    final current = state.dataOrNull;

    if (current != null) emitSuccess(updater(current));
  }

  // ═══════════════════════════════════════════════════════════════════
  // Error handling
  // ═══════════════════════════════════════════════════════════════════

  /// Выполнить действие с автоматическим управлением состояниями
  ///
  /// Loading → Success/Error
  FutureOr<void> guard(FutureOr<T> Function() action) async {
    emitLoading();
    await safeExecute(
      action: () async {
        final result = await action();
        emitSuccess(result);
      },
      onError: emitError,
    );
  }

  /// Обновить данные с загрузкой из источника
  ///
  /// В отличие от guard, не показывает Loading
  FutureOr<void> guardUpdate(FutureOr<T> Function(T current) action) async {
    final current = state.dataOrNull;
    if (current == null) return;

    await safeExecute(
      action: () async {
        final result = await action(current);
        emitSuccess(result);
      },
      onError: emitError,
    );
  }

  /// Выполнить действие без смены состояния
  ///
  /// Ошибки логируются через addError, но состояние не меняется.
  /// Используй для фоновых операций, где не нужно показывать ошибку в UI.
  FutureOr<void> safeExecute({
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
  Future<R?> safeExecuteWithResult<R>({
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
