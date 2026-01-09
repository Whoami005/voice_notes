import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/state/effect/effect_mixin.dart';
import 'package:voice_notes/core/state/shared/initializable.dart';
import 'package:voice_notes/core/state/shared/state_views.dart';

/// Виджет для построения UI на основе [AsyncState].
class AsyncStateBody<C extends BlocBase<AsyncState<T>>, T>
    extends StatelessWidget {
  final C? bloc;

  final Widget Function(BuildContext context, T data) onSuccess;

  final Widget Function(BuildContext context, AppFailure failure)? onError;

  final Widget Function(BuildContext context)? onLoading;

  final Widget Function(BuildContext context)? onInitial;

  final bool Function(AsyncState<T> previous, AsyncState<T> current)? buildWhen;

  final void Function(BuildContext, AsyncState<T>)? listener;

  const AsyncStateBody({
    required this.onSuccess,
    super.key,
    this.bloc,
    this.onError,
    this.onLoading,
    this.onInitial,
    this.buildWhen,
    this.listener,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<C, AsyncState<T>>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) => switch (state) {
        AsyncInitial() => onInitial?.call(context) ?? const SizedBox.shrink(),
        AsyncLoading() => onLoading?.call(context) ?? const StateLoadingView(),
        AsyncError(:final failure) =>
          onError?.call(context, failure) ??
              _buildDefaultError(context, failure),
        AsyncSuccess() => onSuccess(context, state.data),
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, AppFailure failure) {
    final cubit = bloc ?? context.read<C>();

    return StateErrorView(
      message: failure.message,
      onRetry: cubit is Initializable ? (cubit as Initializable).init : null,
    );
  }

  bool _defaultBuildWhen(AsyncState<T> prev, AsyncState<T> curr) =>
      prev.runtimeType != curr.runtimeType;
}

/// Виджет [AsyncState] + Scaffold для loading/error состояний.
class AsyncStateScaffold<C extends BlocBase<AsyncState<T>>, T>
    extends StatelessWidget {
  final C? bloc;

  final PreferredSizeWidget? appBar;

  final String? title;

  final Color? backgroundColor;

  final Widget Function(BuildContext context, T data) onSuccess;

  final Widget Function(BuildContext context, AppFailure failure)? onError;

  final Widget Function(BuildContext context)? onLoading;

  final Widget Function(BuildContext context)? onInitial;

  final bool Function(AsyncState<T> previous, AsyncState<T> current)? buildWhen;

  final void Function(BuildContext, AsyncState<T>)? listener;

  const AsyncStateScaffold({
    required this.onSuccess,
    super.key,
    this.bloc,
    this.backgroundColor,
    this.appBar,
    this.title,
    this.onError,
    this.onLoading,
    this.onInitial,
    this.buildWhen,
    this.listener,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<C, AsyncState<T>>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) => switch (state) {
        AsyncInitial() =>
          onInitial?.call(context) ??
              _wrapWithScaffold(context, const SizedBox.shrink()),
        AsyncLoading() =>
          onLoading?.call(context) ??
              _wrapWithScaffold(context, const StateLoadingView()),
        AsyncError(:final failure) =>
          onError?.call(context, failure) ??
              _wrapWithScaffold(context, _buildDefaultError(context, failure)),
        AsyncSuccess(:final data) => onSuccess(context, data),
      },
    );
  }

  Widget _wrapWithScaffold(BuildContext context, Widget body) {
    return Scaffold(
      appBar:
          appBar ??
          AppBar(title: title != null ? Text(title!) : null, elevation: 0),
      body: body,
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildDefaultError(BuildContext context, AppFailure failure) {
    final cubit = bloc ?? context.read<C>();

    return StateErrorView(
      message: failure.message,
      onRetry: cubit is Initializable ? (cubit as Initializable).init : null,
    );
  }

  bool _defaultBuildWhen(AsyncState<T> prev, AsyncState<T> curr) =>
      prev.runtimeType != curr.runtimeType;
}

/// Consumer для [AsyncState] с поддержкой эффектов.
///
/// Объединяет функциональность BlocConsumer и EffectListener.
///
/// ```dart
/// AsyncStateConsumer<ModelsCubit, List<Model>, AppEffect>(
///   onSuccess: (context, models) => ModelsList(models),
///   effectListener: (context, effect) {
///     if (effect is ShowErrorEffect) showSnackBar(effect.message);
///   },
/// )
/// ```
class AsyncStateConsumer<C extends EffectMixin<E>, T, E>
    extends StatefulWidget {
  /// Cubit (если не предоставлен, берётся из контекста)
  final C? bloc;

  /// Билдер для Success состояния
  final Widget Function(BuildContext context, T data) onSuccess;

  /// Билдер для Error состояния
  final Widget Function(BuildContext context, AppFailure failure)? onError;

  /// Билдер для Loading состояния
  final Widget Function(BuildContext context)? onLoading;

  /// Билдер для Initial состояния
  final Widget Function(BuildContext context)? onInitial;

  /// Callback при получении эффекта
  final void Function(BuildContext context, E effect)? effectListener;

  /// Callback при изменении состояния
  final void Function(BuildContext context, AsyncState<T> state)? listener;

  /// Условие для перестроения виджета
  final bool Function(AsyncState<T> previous, AsyncState<T> current)? buildWhen;

  const AsyncStateConsumer({
    required this.onSuccess,
    super.key,
    this.bloc,
    this.onError,
    this.onLoading,
    this.onInitial,
    this.effectListener,
    this.listener,
    this.buildWhen,
  });

  @override
  State<AsyncStateConsumer<C, T, E>> createState() =>
      _AsyncStateConsumerState<C, T, E>();
}

class _AsyncStateConsumerState<C extends EffectMixin<E>, T, E>
    extends State<AsyncStateConsumer<C, T, E>> {
  StreamSubscription<E>? _effectSubscription;
  late C _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.bloc ?? context.read<C>();
    _subscribeToEffects();
  }

  @override
  void didUpdateWidget(AsyncStateConsumer<C, T, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCubit = oldWidget.bloc ?? context.read<C>();
    final newCubit = widget.bloc ?? oldCubit;

    if (oldCubit != newCubit) {
      _unsubscribeFromEffects();
      _cubit = newCubit;
      _subscribeToEffects();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = widget.bloc ?? context.read<C>();

    if (_cubit != cubit) {
      _unsubscribeFromEffects();
      _cubit = cubit;
      _subscribeToEffects();
    }
  }

  void _subscribeToEffects() {
    if (widget.effectListener == null) return;

    _effectSubscription = _cubit.effects.listen((effect) {
      if (mounted) widget.effectListener!(context, effect);
    });
  }

  void _unsubscribeFromEffects() {
    _effectSubscription?.cancel();
    _effectSubscription = null;
  }

  @override
  void dispose() {
    _unsubscribeFromEffects();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cast cubit to BlocBase<AsyncState<T>> for BlocConsumer
    final blocBase = _cubit as BlocBase<AsyncState<T>>;

    return BlocConsumer<BlocBase<AsyncState<T>>, AsyncState<T>>(
      bloc: blocBase,
      buildWhen: widget.buildWhen ?? _defaultBuildWhen,
      listener: widget.listener ?? (_, _) {},
      builder: (context, state) => switch (state) {
        AsyncInitial() =>
          widget.onInitial?.call(context) ?? const SizedBox.shrink(),
        AsyncLoading() =>
          widget.onLoading?.call(context) ?? const StateLoadingView(),
        AsyncError(:final failure) =>
          widget.onError?.call(context, failure) ??
              _buildDefaultError(context, failure),
        AsyncSuccess() => widget.onSuccess(context, state.data),
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, AppFailure failure) {
    return StateErrorView(
      message: failure.message,
      onRetry: _cubit is Initializable ? (_cubit as Initializable).init : null,
    );
  }

  bool _defaultBuildWhen(AsyncState<T> prev, AsyncState<T> curr) =>
      prev.runtimeType != curr.runtimeType;
}
