import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/async/async_cubit.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';
import 'package:voice_notes/core/state/effect/effect_listener.dart';
import 'package:voice_notes/core/state/shared/initializable.dart';
import 'package:voice_notes/core/state/shared/state_views.dart';

// ═══════════════════════════════════════════════════════════════════
// AsyncStateBody
// ═══════════════════════════════════════════════════════════════════

/// Виджет для построения UI на основе [AsyncState].
///
/// Поддерживает автоматическую обработку эффектов через [HandledEffect].
class AsyncStateBody<C extends AsyncCubit<T>, T> extends StatelessWidget {
  final C? bloc;

  final Widget Function(BuildContext context, T data) onSuccess;

  final Widget Function(BuildContext context, AppFailure failure)? onError;

  final Widget Function(BuildContext context)? onLoading;

  final Widget Function(BuildContext context)? onInitial;

  final bool Function(AsyncState<T> previous, AsyncState<T> current)? buildWhen;

  final void Function(BuildContext, AsyncState<T>)? listener;

  /// Кастомная обработка эффектов. Если null — автообработка [HandledEffect].
  final void Function(BuildContext, BaseEffect)? onEffect;

  /// Включить/выключить прослушивание эффектов. По умолчанию true.
  final bool listenToEffects;

  const AsyncStateBody({
    required this.onSuccess,
    super.key,
    this.bloc,
    this.onError,
    this.onLoading,
    this.onInitial,
    this.buildWhen,
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
      buildWhen: buildWhen,
      listener: listener,
    );

    if (listenToEffects) {
      return EffectListener<C, BaseEffect>(
        bloc: bloc,
        listener: _handleEffect,
        child: child,
      );
    }

    return child;
  }

  void _handleEffect(BuildContext context, BaseEffect effect) {
    if (onEffect != null) {
      onEffect!(context, effect);
    } else if (effect is HandledEffect) {
      effect.handle(context);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// AsyncStateScaffold
// ═══════════════════════════════════════════════════════════════════

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

  final bool Function(AsyncState<T> previous, AsyncState<T> current)? buildWhen;

  final void Function(BuildContext, AsyncState<T>)? listener;

  /// Кастомная обработка эффектов. Если null — автообработка [HandledEffect].
  final void Function(BuildContext, BaseEffect)? onEffect;

  /// Включить/выключить прослушивание эффектов. По умолчанию true.
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
    this.buildWhen,
    this.listener,
    this.onEffect,
    this.listenToEffects = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = BlocConsumer<C, AsyncState<T>>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) => switch (state) {
        AsyncInitial() =>
          onInitial?.call(context) ??
              _ScaffoldWrapper(
                appBar: appBar,
                title: title,
                backgroundColor: backgroundColor,
                child: const SizedBox.shrink(),
              ),
        AsyncLoading() =>
          onLoading?.call(context) ??
              _ScaffoldWrapper(
                appBar: appBar,
                title: title,
                backgroundColor: backgroundColor,
                child: const StateLoadingView(),
              ),
        AsyncError(:final failure) =>
          onError?.call(context, failure) ??
              _ScaffoldWrapper(
                appBar: appBar,
                title: title,
                backgroundColor: backgroundColor,
                child: _DefaultErrorView<C>(bloc: bloc, failure: failure),
              ),
        AsyncSuccess(:final data) => onSuccess(context, data),
      },
    );

    if (listenToEffects) {
      return EffectListener<C, BaseEffect>(
        bloc: bloc,
        listener: _handleEffect,
        child: child,
      );
    }

    return child;
  }

  void _handleEffect(BuildContext context, BaseEffect effect) {
    if (onEffect != null) {
      onEffect!(context, effect);
    } else if (effect is HandledEffect) {
      effect.handle(context);
    }
  }

  bool _defaultBuildWhen(AsyncState<T> prev, AsyncState<T> curr) =>
      prev.runtimeType != curr.runtimeType;
}

// ═══════════════════════════════════════════════════════════════════
// Private widgets
// ═══════════════════════════════════════════════════════════════════

class _AsyncStateBuilder<C extends AsyncCubit<T>, T> extends StatelessWidget {
  final C? bloc;
  final Widget Function(BuildContext, T) onSuccess;
  final Widget Function(BuildContext, AppFailure)? onError;
  final Widget Function(BuildContext)? onLoading;
  final Widget Function(BuildContext)? onInitial;
  final bool Function(AsyncState<T>, AsyncState<T>)? buildWhen;
  final void Function(BuildContext, AsyncState<T>)? listener;

  const _AsyncStateBuilder({
    required this.onSuccess,
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
              _DefaultErrorView<C>(bloc: bloc, failure: failure),
        AsyncSuccess(:final data) => onSuccess(context, data),
      },
    );
  }

  bool _defaultBuildWhen(AsyncState<T> prev, AsyncState<T> curr) =>
      prev.runtimeType != curr.runtimeType;
}

class _DefaultErrorView<C> extends StatelessWidget {
  final C? bloc;
  final AppFailure failure;

  const _DefaultErrorView({required this.failure, this.bloc});

  @override
  Widget build(BuildContext context) {
    final cubit = bloc ?? context.read<C>();

    return StateErrorView(
      message: failure.message,
      onRetry: cubit is Initializable ? (cubit as Initializable).init : null,
    );
  }
}

class _ScaffoldWrapper extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final String? title;
  final Color? backgroundColor;
  final Widget child;

  const _ScaffoldWrapper({
    required this.child,
    this.appBar,
    this.title,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          appBar ??
          AppBar(title: title != null ? Text(title!) : null, elevation: 0),
      body: child,
      backgroundColor: backgroundColor,
    );
  }
}
