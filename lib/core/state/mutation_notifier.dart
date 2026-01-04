import 'package:flutter/material.dart';

class MutationNotifier<T> extends ValueNotifier<MutationState<T>> {
  final String? debugLabel;
  final Duration? timeout;

  MutationNotifier({this.debugLabel, this.timeout})
    : super(const MutationIdle());

  bool get isIdle => value is MutationIdle<T>;

  bool get isPending => value is MutationPending<T>;

  bool get isSuccess => value is MutationSuccess<T>;

  bool get isError => value is MutationError<T>;

  T? get dataOrNull =>
      value is MutationSuccess<T> ? (value as MutationSuccess<T>).data : null;

  Object? get errorOrNull =>
      value is MutationError<T> ? (value as MutationError<T>).error : null;

  Future<void> run(Future<T> Function() action) async {
    try {
      value = const MutationPending();

      final future = action();
      final result = timeout != null
          ? await future.timeout(timeout!)
          : await future;

      value = MutationSuccess(result);
    } catch (error, stackTrace) {
      value = MutationError(error, stackTrace);
    }
  }

  void reset() => value = const MutationIdle();
}

// BUILDER ДЛЯ УДОБНОЙ ПОДПИСКИ НА СОСТОЯНИЕ

class MutationListenableBuilder<T> extends StatelessWidget {
  final Widget? child;
  final MutationNotifier<T> mutationListenable;
  final Widget Function(
    BuildContext context,
    MutationState<T> state,
    Widget? child,
  )
  builder;

  const MutationListenableBuilder({
    required this.mutationListenable,
    required this.builder,
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MutationState<T>>(
      valueListenable: mutationListenable,
      builder: builder,
      child: child,
    );
  }
}

// СОСТОЯНИЯ МУТАЦИИ (Sealed classes для pattern matching)

sealed class MutationState<T> {
  const MutationState();

  /// Маппинг состояния на нужный тип
  R when<R>({
    required R Function() idle,
    required R Function() pending,
    required R Function(T data) success,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle() => idle(),
      MutationPending() => pending(),
      MutationSuccess() => success(state.data),
      MutationError() => error(state.error, state.stackTrace),
    };
  }

  /// Маппинг с дефолтными значениями
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? idle,
    R Function()? pending,
    R Function(T data)? success,
    R Function(Object error, StackTrace? stackTrace)? error,
  }) {
    final state = this;

    return switch (state) {
      MutationIdle() => idle?.call() ?? orElse(),
      MutationPending() => pending?.call() ?? orElse(),
      MutationSuccess() => success?.call(state.data) ?? orElse(),
      MutationError() => error?.call(state.error, state.stackTrace) ?? orElse(),
    };
  }
}

class MutationIdle<T> extends MutationState<T> {
  const MutationIdle();
}

class MutationPending<T> extends MutationState<T> {
  const MutationPending();
}

class MutationSuccess<T> extends MutationState<T> {
  final T data;
  final DateTime completedAt;

  MutationSuccess(this.data) : completedAt = DateTime.now();
}

class MutationError<T> extends MutationState<T> {
  final Object error;
  final StackTrace? stackTrace;
  final DateTime occurredAt;

  MutationError(this.error, [this.stackTrace]) : occurredAt = DateTime.now();
}
