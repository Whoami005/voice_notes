import 'dart:async';

import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/effect/common_effects.dart';
import 'package:voice_notes/core/state/effect/effect_base.dart';
import 'package:voice_notes/core/state/status/status_state.dart';

/// Cubit для работы с [StatusState] — enum-based состояния.
///
/// Поддерживает generic тип эффектов `E`.
/// Для использования с [AppEffect] используй typedef [AppStatusCubit].
///
/// ```dart
/// class FoldersCubit extends StatusCubit<FoldersState, AppEffect> { ... }
///
/// // Или с typedef:
/// class FoldersCubit extends AppStatusCubit<FoldersState> { ... }
/// ```
abstract class StatusCubit<S extends StatusState, E> extends EffectCubit<S, E> {
  StatusCubit(super.initialState);

  // ═══════════════════════════════════════════════════════════════════
  // Emitters
  // ═══════════════════════════════════════════════════════════════════

  /// Установить статус init и очистить ошибку
  void emitInit() => emit(state.copyWith(status: Status.init) as S);

  /// Установить статус loading и очистить ошибку
  void emitLoading() => emit(state.copyWith(status: Status.loading) as S);

  /// Установить статус success на новом состоянии и очистить ошибку
  void emitSuccess(S newState) =>
      emit(newState.copyWith(status: Status.success) as S);

  /// Установить статус error с ошибкой
  void emitError(AppFailure failure) => emit(
    state.copyWith(status: Status.error, failure: failure) as S,
  );

  // ═══════════════════════════════════════════════════════════════════
  // State Operations
  // ═══════════════════════════════════════════════════════════════════

  /// Loading → Success/Error.
  ///
  /// Используй для начальной загрузки данных.
  Future<void> load(FutureOr<S> Function() action) async {
    emitLoading();
    await guard(action);
  }

  /// Success/Error без Loading.
  ///
  /// Используй для обновлений без индикатора загрузки.
  Future<void> guard(
    FutureOr<S> Function() action, {
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
}

/// [StatusCubit] с дефолтным типом эффектов [AppEffect].
typedef AppStatusCubit<S extends StatusState> = StatusCubit<S, AppEffect>;
