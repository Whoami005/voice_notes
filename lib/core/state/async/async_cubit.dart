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

  void emitInitial() => safeEmit(const AsyncState.initial());

  void emitLoading() => safeEmit(const AsyncState.loading());

  void emitSuccess(T data, {bool isEmpty = false}) =>
      safeEmit(AsyncState.success(data, isEmpty: isEmpty));

  void emitError(AppFailure failure) => safeEmit(AsyncState.error(failure));

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
    emitLoading();
    await guard(action);
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
      onError == null ? emitError(failure) : onError(failure);
    }
  }

  /// Выполнить действие с обработкой ошибок через effect.
  ///
  /// Используй для действий пользователя, требующих error feedback.
  /// Ничего не делает если state не Success.
  ///
  /// ```dart
  /// Future<void> deleteItem(String id) => guardAction((data) async {
  ///   await repository.delete(id);
  ///   emitSuccess(data.copyWith(items: data.items.where((i) => i.id != id)));
  /// });
  /// ```
  Future<void> guardAction(
    FutureOr<void> Function(T current) action, {
    void Function(AppFailure failure)? onError,
  }) async {
    final data = state.dataOrNull;
    if (data == null) return;

    try {
      await action(data);
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
