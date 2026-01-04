import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/status_state/status_state.dart';

/// Кубит для StatusState
abstract class StatusCubit<T extends StatusState> extends Cubit<T> {
  StatusCubit(super.initialState);

  // ═══════════════════════════════════════════════════════════════════
  // Convenience emitters
  // ═══════════════════════════════════════════════════════════════════

  /// Установить статус init и очистить ошибку
  void emitInit() => emit(state.copyWith(status: LogicStateStatus.init) as T);

  /// Установить статус loading и очистить ошибку
  void emitLoading() =>
      emit(state.copyWith(status: LogicStateStatus.loading) as T);

  /// Установить статус success на новом состоянии и очистить ошибку
  void emitSuccess(T newState) =>
      emit(newState.copyWith(status: LogicStateStatus.success) as T);

  /// Установить статус error с ошибкой
  void emitError(AppFailure failure) => emit(
    state.copyWith(status: LogicStateStatus.error, failure: failure) as T,
  );

  // ═══════════════════════════════════════════════════════════════════
  // State transformation
  // ═══════════════════════════════════════════════════════════════════

  /// Выполнить действие с автоматическим управлением состояниями.
  ///
  /// Loading → Success/Error.
  /// Используй для начальной загрузки данных (init).
  Future<void> load(FutureOr<T> Function() action) async {
    emitLoading();
    await guard(action);
  }

  /// Выполнить действие без показа индикатора загрузки.
  ///
  /// Success/Error (без Loading).
  /// Используй для обновлений без показа индикатора загрузки.
  Future<void> guard(
    FutureOr<T> Function() action, {
    void Function(AppFailure failure)? onError,
  }) async {
    try {
      final newState = await action();
      emitSuccess(newState);
    } catch (e, s) {
      final failure = logError(e, s);
      onError != null ? onError(failure) : emitError(failure);
    }
  }

  /// Логировать ошибку и вернуть AppFailure
  ///
  /// Добавляет ошибку в error stream кубита через addError
  AppFailure logError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);
    return AppFailure.from(error, stackTrace);
  }
}
