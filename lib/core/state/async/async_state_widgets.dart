import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/async/async_cubit.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';
import 'package:voice_notes/core/state/effect/effect_listener.dart';
import 'package:voice_notes/core/state/shared/shared_state_widgets.dart';
import 'package:voice_notes/core/state/shared/state_utils.dart';
import 'package:voice_notes/core/state/shared/state_views.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AsyncStateBody
// ═══════════════════════════════════════════════════════════════════════════

/// Виджет для построения UI на основе [AsyncState].
///
/// Поддерживает автоматическую обработку эффектов через [HandledEffect].
class AsyncStateBody<C extends AsyncCubit<T>, T> extends StatelessWidget {
  final C? bloc;
  final Widget Function(BuildContext context, T data) onSuccess;
  final Widget Function(BuildContext context, AppFailure failure)? onError;
  final Widget Function(BuildContext context)? onLoading;
  final Widget Function(BuildContext context)? onInitial;
  final Widget Function(BuildContext context, T data)? onEmpty;
  final bool Function(AsyncState<T> previous, AsyncState<T> current)? buildWhen;
  final bool buildAlways;
  final void Function(BuildContext, AsyncState<T>)? listener;
  final void Function(BuildContext, BaseEffect)? onEffect;
  final bool listenToEffects;

  const AsyncStateBody({
    required this.onSuccess,
    super.key,
    this.bloc,
    this.onError,
    this.onLoading,
    this.onInitial,
    this.onEmpty,
    this.buildWhen,
    this.buildAlways = false,
    this.listener,
    this.onEffect,
    this.listenToEffects = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = _AsyncStateBuilder<C, T>(
      bloc: bloc,
      onSuccess: onSuccess,
      onError: onError,
      onLoading: onLoading,
      onInitial: onInitial,
      onEmpty: onEmpty,
      buildWhen: buildWhen,
      buildAlways: buildAlways,
      listener: listener,
    );

    if (!listenToEffects) return child;

    return EffectListener<C, BaseEffect>(
      bloc: bloc,
      listener: (ctx, e) => StateUtils.handleEffect(ctx, e, onEffect: onEffect),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AsyncStateScaffold
// ═══════════════════════════════════════════════════════════════════════════

/// Виджет [AsyncState] + Scaffold для loading/error состояний.
///
/// Поддерживает автоматическую обработку эффектов через [HandledEffect].
class AsyncStateScaffold<C extends AsyncCubit<T>, T> extends StatelessWidget {
  final C? bloc;
  final PreferredSizeWidget? appBar;
  final String? title;
  final Color? backgroundColor;
  final Widget Function(BuildContext context, T data) onSuccess;
  final Widget Function(BuildContext context, AppFailure failure)? onError;
  final Widget Function(BuildContext context)? onLoading;
  final Widget Function(BuildContext context)? onInitial;
  final Widget Function(BuildContext context, T data)? onEmpty;
  final bool Function(AsyncState<T> previous, AsyncState<T> current)? buildWhen;
  final bool buildAlways;
  final void Function(BuildContext, AsyncState<T>)? listener;
  final void Function(BuildContext, BaseEffect)? onEffect;
  final bool listenToEffects;

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
    this.onEmpty,
    this.buildWhen,
    this.buildAlways = false,
    this.listener,
    this.onEffect,
    this.listenToEffects = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = _AsyncStateBuilder<C, T>(
      bloc: bloc,
      onSuccess: onSuccess,
      onError: onError,
      onLoading: onLoading,
      onInitial: onInitial,
      onEmpty: onEmpty,
      buildWhen: buildWhen,
      buildAlways: buildAlways,
      listener: listener,
      stateWrapper: (child) => StateScaffoldWrapper(
        appBar: appBar,
        title: title,
        backgroundColor: backgroundColor,
        child: child,
      ),
    );

    if (!listenToEffects) return child;

    return EffectListener<C, BaseEffect>(
      bloc: bloc,
      listener: (ctx, e) => StateUtils.handleEffect(ctx, e, onEffect: onEffect),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Private Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _AsyncStateBuilder<C extends AsyncCubit<T>, T> extends StatelessWidget {
  final C? bloc;
  final Widget Function(BuildContext, T) onSuccess;
  final Widget Function(BuildContext, AppFailure)? onError;
  final Widget Function(BuildContext)? onLoading;
  final Widget Function(BuildContext)? onInitial;
  final Widget Function(BuildContext, T)? onEmpty;
  final bool Function(AsyncState<T>, AsyncState<T>)? buildWhen;
  final bool buildAlways;
  final void Function(BuildContext, AsyncState<T>)? listener;

  /// Опциональный wrapper для состояний loading/error/initial.
  final Widget Function(Widget child)? stateWrapper;

  const _AsyncStateBuilder({
    required this.onSuccess,
    this.bloc,
    this.onError,
    this.onLoading,
    this.onInitial,
    this.onEmpty,
    this.buildWhen,
    this.buildAlways = false,
    this.listener,
    this.stateWrapper,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<C, AsyncState<T>>(
      bloc: bloc,
      buildWhen: buildAlways ? null : (buildWhen ?? _defaultBuildWhen),
      listener: listener ?? (_, _) {},
      builder: (context, state) => switch (state) {
        AsyncInitial() => _wrap(
            onInitial?.call(context) ?? const SizedBox.shrink(),
          ),
        AsyncLoading() => _wrap(
            onLoading?.call(context) ?? const StateLoadingView(),
          ),
        AsyncError(:final failure) => _wrap(
            onError?.call(context, failure) ??
                StateDefaultErrorView<C>(bloc: bloc, failure: failure),
          ),
        AsyncSuccess(:final data, :final isEmpty) =>
          isEmpty && onEmpty != null
              ? onEmpty!(context, data)
              : onSuccess(context, data),
      },
    );
  }

  Widget _wrap(Widget child) => stateWrapper?.call(child) ?? child;

  bool _defaultBuildWhen(AsyncState<T> prev, AsyncState<T> curr) =>
      prev.runtimeType != curr.runtimeType;
}
