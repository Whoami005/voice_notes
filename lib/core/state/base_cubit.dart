import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_state.dart';
import 'package:voice_notes/core/state/initializable.dart';

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
    : super(initialState ?? const BaseState.initial()) {
    _initializable();
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
  /// Поддерживает sync и async.
  FutureOr<void> withData(FutureOr<void> Function(T data) action) {
    final data = state.dataOrNull;
    if (data == null) return null;

    final result = action(data);

    if (result is Future<void>) return result;
  }

  // ═══════════════════════════════════════════════════════════════════
  // State transformation
  // ═══════════════════════════════════════════════════════════════════

  /// Выполнить действие с автоматическим управлением состояниями.
  ///
  /// Loading → Success/Error.
  /// Используй для начальной загрузки данных (init).
  Future<void> guard(FutureOr<T> Function() action) async {
    emitLoading();
    await safeExecute(
      action: () async => emitSuccess(await action()),
      onError: emitError,
    );
  }

  /// Трансформировать данные с обработкой ошибок.
  ///
  /// При ошибке emitError, иначе emitSuccess.
  /// Используй когда возможны исключения (например, pull-to-refresh).
  Future<void> updateSafe(FutureOr<T> Function(T current) updater) async {
    final data = state.dataOrNull;
    if (data == null) return;

    await safeExecute(
      action: () async => emitSuccess(await updater(data)),
      onError: emitError,
    );
  }

  /// Трансформировать данные и emit Success.
  ///
  /// Ничего не делает, если состояние не Success.
  /// Без обработки ошибок — используй для безопасных операций.
  /// Поддерживает sync и async.
  FutureOr<void> update(FutureOr<T> Function(T current) updater) {
    final data = state.dataOrNull;
    if (data == null) return null;

    final result = updater(data);

    if (result is Future<T>) {
      return result.then(emitSuccess);
    } else {
      emitSuccess(result);
    }
  }

  /// Выполнить действие без смены состояния.
  ///
  /// Ошибки логируются через addError, но состояние не меняется.
  /// Используй для фоновых операций, где не нужно показывать ошибку в UI.
  /// Поддерживает sync и async.
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

  Future<void> _initializable() =>
      safeExecute(action: (this as Initializable).init, onError: emitError);
}
