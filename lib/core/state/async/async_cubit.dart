import 'dart:async';

import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';
import 'package:voice_notes/core/state/effect/common_effects.dart';
import 'package:voice_notes/core/state/effect/effect_base.dart';

/// Cubit для работы с [AsyncState] — Initial/Loading/Success/Error.
///
/// Использует [BaseEffect] для системы эффектов.
///
/// ```dart
/// class ModelsCubit extends AsyncCubit<List<Model>> {
///   Future<void> init() => load(() => repository.getModels());
/// }
/// ```
abstract class AsyncCubit<T> extends EffectCubit<AsyncState<T>, BaseEffect> {
  AsyncCubit([AsyncState<T>? initialState])
    : super(initialState ?? const AsyncState.initial());

  // ═══════════════════════════════════════════════════════════════════
  // Emitters
  // ═══════════════════════════════════════════════════════════════════

  void emitInitial() => emit(const AsyncState.initial());

  void emitLoading() => emit(const AsyncState.loading());

  void emitSuccess(T data) => emit(AsyncState.success(data));

  void emitError(AppFailure failure) => emit(AsyncState.error(failure));

  // ═══════════════════════════════════════════════════════════════════
  // State Operations
  // ═══════════════════════════════════════════════════════════════════

  /// Выполнить действие с текущими данными.
  ///
  /// Возвращает null если состояние не Success.
  FutureOr<R?> whenData<R>(FutureOr<R> Function(T data) action) {
    final data = state.dataOrNull;
    if (data == null) return null;

    return action(data);
  }

  /// Loading → Success/Error.
  ///
  /// Используй для начальной загрузки данных.
  Future<void> load(FutureOr<T> Function() action) async {
    try {
      emitLoading();

      emitSuccess(await action());
    } catch (e, s) {
      final failure = logError(e, s);
      emitError(failure);
    }
  }

  /// Success/Error без Loading.
  ///
  /// Используй для обновления без индикатора загрузки.
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

  /// Трансформировать текущие данные.
  FutureOr<void> transform(
    FutureOr<void> Function(T current) transformer, {
    void Function(AppFailure failure)? onError,
  }) async {
    final data = state.dataOrNull;
    if (data == null) return;

    try {
      await transformer(data);
    } catch (e, s) {
      final failure = logError(e, s);
      onError == null ? emitEffect(ShowErrorEffect(failure)) : onError(failure);
    }
  }

  /// Подписаться на стрим данных.
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
}
