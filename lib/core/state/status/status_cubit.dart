import 'dart:async';

import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/effect/app_effect_error_mixin.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';
import 'package:voice_notes/core/state/effect/effect_base.dart';
import 'package:voice_notes/core/state/status/status_state.dart';

/// Cubit для работы с [StatusState] — enum-based состояния.
///
/// Использует [BaseEffect] для системы эффектов.
///
/// ```dart
/// class FoldersCubit extends StatusCubit<FoldersState> {
///   Future<void> init() => load(() => FoldersState(...));
/// }
/// ```
abstract class StatusCubit<S extends StatusState>
    extends EffectCubit<S, BaseEffect>
    with AppEffectErrorMixin<S> {
  StatusCubit(super.initialState);

  // ═══════════════════════════════════════════════════════════════════
  // Emitters
  // ═══════════════════════════════════════════════════════════════════

  /// Установить статус init и очистить ошибку
  void emitInit() => safeEmit(state.copyWith(status: Status.init) as S);

  /// Установить статус loading и очистить ошибку
  void emitLoading() => safeEmit(state.copyWith(status: Status.loading) as S);

  /// Установить статус success на новом состоянии и очистить ошибку
  void emitSuccess(S newState) =>
      safeEmit(newState.copyWith(status: Status.success) as S);

  /// Установить статус error с ошибкой
  void emitError(AppFailure failure) =>
      safeEmit(state.copyWith(status: Status.error, failure: failure) as S);

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
