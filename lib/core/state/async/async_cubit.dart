import 'dart:async';

import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/state/effect/common_effects.dart';
import 'package:voice_notes/core/state/effect/effect_base.dart';

/// Cubit для работы с [AsyncState] — Initial/Loading/Success/Error.
///
/// Поддерживает generic тип эффектов `E`.
/// Для использования с [AppEffect] используй typedef [AppAsyncCubit].
///
/// ```dart
/// class ModelsCubit extends AsyncCubit<List<Model>, AppEffect> {
///   Future<void> init() => load(() => repository.getModels());
/// }
///
/// // Или с typedef:
/// class ModelsCubit extends AppAsyncCubit<List<Model>> { ... }
/// ```
abstract class AsyncCubit<T, E> extends EffectCubit<AsyncState<T>, E> {
  AsyncCubit([AsyncState<T>? initialState])
    : super(initialState ?? const AsyncState.initial());

  // ═══════════════════════════════════════════════════════════════════
  // Getters
  // ═══════════════════════════════════════════════════════════════════

  /// Данные или null
  T? get dataOrNull => state.dataOrNull;

  /// Данные или исключение
  T get requireData => state.requireData;

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
    emitLoading();
    await execute(
      action: () async => emitSuccess(await action()),
      onError: emitError,
    );
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
  ///
  /// Ничего не делает если состояние не Success.
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

  /// Модифицировать данные и вернуть результат.
  ///
  /// Возвращает null если состояние не Success.
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

/// [AsyncCubit] с дефолтным типом эффектов [AppEffect].
typedef AppAsyncCubit<T> = AsyncCubit<T, AppEffect>;
