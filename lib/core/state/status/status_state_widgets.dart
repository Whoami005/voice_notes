import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';
import 'package:voice_notes/core/state/effect/effect_listener.dart';
import 'package:voice_notes/core/state/shared/shared_state_widgets.dart';
import 'package:voice_notes/core/state/shared/state_utils.dart';
import 'package:voice_notes/core/state/shared/state_views.dart';
import 'package:voice_notes/core/state/status/status_cubit.dart';
import 'package:voice_notes/core/state/status/status_state.dart';

// ═══════════════════════════════════════════════════════════════════════════
// StatusStateBody
// ═══════════════════════════════════════════════════════════════════════════

/// Виджет для построения UI на основе [StatusState].
///
/// Поддерживает автоматическую обработку эффектов через [HandledEffect].
class StatusStateBody<C extends StatusCubit<S>, S extends StatusState>
    extends StatelessWidget {
  final C? bloc;
  final Widget Function(BuildContext context, S state) onSuccess;
  final Widget Function(BuildContext context, S state, AppFailure? failure)?
  onError;
  final Widget Function(BuildContext context, S state)? onLoading;
  final Widget Function(BuildContext context, S state)? onInitial;
  final bool Function(S previous, S current)? buildWhen;
  final void Function(BuildContext context, S state)? listener;
  final void Function(BuildContext, BaseEffect)? onEffect;
  final bool listenToEffects;

  const StatusStateBody({
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
    final child = _StatusStateBuilder<C, S>(
      bloc: bloc,
      onSuccess: onSuccess,
      onError: onError,
      onLoading: onLoading,
      onInitial: onInitial,
      buildWhen: buildWhen,
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
// StatusStateScaffold
// ═══════════════════════════════════════════════════════════════════════════

/// Виджет [StatusState] + Scaffold для loading/error состояний.
///
/// Поддерживает автоматическую обработку эффектов через [HandledEffect].
class StatusStateScaffold<C extends StatusCubit<S>, S extends StatusState>
    extends StatelessWidget {
  final C? bloc;
  final PreferredSizeWidget? appBar;
  final String? title;
  final Color? backgroundColor;
  final Widget Function(BuildContext context, S state) onSuccess;
  final Widget Function(BuildContext context, S state, AppFailure? failure)?
  onError;
  final Widget Function(BuildContext context, S state)? onLoading;
  final Widget Function(BuildContext context, S state)? onInitial;
  final bool Function(S previous, S current)? buildWhen;
  final void Function(BuildContext context, S state)? listener;
  final void Function(BuildContext, BaseEffect)? onEffect;
  final bool listenToEffects;

  const StatusStateScaffold({
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
    final child = _StatusStateBuilder<C, S>(
      bloc: bloc,
      onSuccess: onSuccess,
      onError: onError,
      onLoading: onLoading,
      onInitial: onInitial,
      buildWhen: buildWhen,
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

class _StatusStateBuilder<C extends StatusCubit<S>, S extends StatusState>
    extends StatelessWidget {
  final C? bloc;
  final Widget Function(BuildContext, S) onSuccess;
  final Widget Function(BuildContext, S, AppFailure?)? onError;
  final Widget Function(BuildContext, S)? onLoading;
  final Widget Function(BuildContext, S)? onInitial;
  final bool Function(S, S)? buildWhen;
  final void Function(BuildContext, S)? listener;

  /// Опциональный wrapper для состояний loading/error/initial.
  final Widget Function(Widget child)? stateWrapper;

  const _StatusStateBuilder({
    required this.onSuccess,
    this.bloc,
    this.onError,
    this.onLoading,
    this.onInitial,
    this.buildWhen,
    this.listener,
    this.stateWrapper,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<C, S>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) => switch (state.status) {
        Status.init =>
          onInitial?.call(context, state) ?? _wrap(const SizedBox.shrink()),

        Status.loading =>
          onLoading?.call(context, state) ?? _wrap(const StateLoadingView()),
        Status.error =>
          onError?.call(context, state, state.failure) ??
              _wrap(
                StateDefaultErrorView<C>(bloc: bloc, failure: state.failure),
              ),
        Status.success => onSuccess(context, state),
      },
    );
  }

  Widget _wrap(Widget child) => stateWrapper?.call(child) ?? child;

  bool _defaultBuildWhen(S prev, S curr) => prev.status != curr.status;
}
