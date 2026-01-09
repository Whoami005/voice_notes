import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';

/// Mixin с общими утилитами для всех Cubit'ов и Bloc'ов.
///
/// Предоставляет:
/// - [logError] — логирование ошибок через addError
/// - [safeEmit] — безопасный emit (игнорирует если cubit закрыт)
/// - [execute] — выполнение действия с обработкой ошибок
mixin CubitMixin<S> on BlocBase<S> {
  /// Логирует ошибку через addError и возвращает AppFailure.
  ///
  /// Ошибка попадает в BlocObserver.onError для централизованного логирования.
  AppFailure logError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);
    return AppFailure.from(error, stackTrace);
  }

  /// Безопасный emit — игнорирует вызов если cubit уже закрыт.
  ///
  /// Полезно для асинхронных операций, которые могут завершиться
  /// после закрытия cubit'а.
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }

  /// Выполняет действие с автоматической обработкой ошибок.
  ///
  /// Не меняет состояние — используй для фоновых операций.
  Future<void> execute({
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
}
