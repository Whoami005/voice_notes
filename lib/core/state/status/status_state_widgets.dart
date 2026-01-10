import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';
import 'package:voice_notes/core/state/effect/effect_listener.dart';
import 'package:voice_notes/core/state/shared/initializable.dart';
import 'package:voice_notes/core/state/shared/state_views.dart';
import 'package:voice_notes/core/state/status/status_cubit.dart';
import 'package:voice_notes/core/state/status/status_state.dart';

// ═══════════════════════════════════════════════════════════════════
// StatusStateBody
// ═══════════════════════════════════════════════════════════════════

/// Виджет для построения UI на основе [StatusState].
///
/// Поддерживает автоматическую обработку эффектов через [HandledEffect].
class StatusStateBody<C extends StatusCubit<S>, S extends StatusState>
    extends StatelessWidget {
  final C? bloc;

  /// Получает полный state (не только данные)
  final Widget Function(BuildContext context, S state) onSuccess;

  final Widget Function(BuildContext context, S state, AppFailure? failure)?
  onError;

  final Widget Function(BuildContext context, S state)? onLoading;

  final Widget Function(BuildContext context, S state)? onInitial;

  final bool Function(S previous, S current)? buildWhen;

  final void Function(BuildContext context, S state)? listener;

  /// Кастомная обработка эффектов. Если null — автообработка [HandledEffect].
  final void Function(BuildContext, BaseEffect)? onEffect;

  /// Включить/выключить прослушивание эффектов. По умолчанию true.
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
// StatusStateScaffold
// ═══════════════════════════════════════════════════════════════════

/// Виджет [StatusState] + Scaffold для loading/error состояний.
///
/// Поддерживает автоматическую обработку эффектов через [HandledEffect].
class StatusStateScaffold<C extends StatusCubit<S>, S extends StatusState>
    extends StatelessWidget {
  final C? bloc;

  final PreferredSizeWidget? appBar;

  final String? title;

  final Color? backgroundColor;

  /// Получает полный state (не только данные)
  final Widget Function(BuildContext context, S state) onSuccess;

  final Widget Function(BuildContext context, S state, AppFailure? failure)?
  onError;

  final Widget Function(BuildContext context, S state)? onLoading;

  final Widget Function(BuildContext context, S state)? onInitial;

  final bool Function(S previous, S current)? buildWhen;

  final void Function(BuildContext context, S state)? listener;

  /// Кастомная обработка эффектов. Если null — автообработка [HandledEffect].
  final void Function(BuildContext, BaseEffect)? onEffect;

  /// Включить/выключить прослушивание эффектов. По умолчанию true.
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
    final child = BlocConsumer<C, S>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) => switch (state.status) {
        Status.init =>
          onInitial?.call(context, state) ??
              _ScaffoldWrapper(
                appBar: appBar,
                title: title,
                backgroundColor: backgroundColor,
                child: const SizedBox.shrink(),
              ),
        Status.loading =>
          onLoading?.call(context, state) ??
              _ScaffoldWrapper(
                appBar: appBar,
                title: title,
                backgroundColor: backgroundColor,
                child: const StateLoadingView(),
              ),
        Status.error =>
          onError?.call(context, state, state.failure) ??
              _ScaffoldWrapper(
                appBar: appBar,
                title: title,
                backgroundColor: backgroundColor,
                child: _DefaultErrorView<C>(bloc: bloc, failure: state.failure),
              ),
        Status.success => onSuccess(context, state),
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

  bool _defaultBuildWhen(S prev, S curr) => prev.status != curr.status;
}

// ═══════════════════════════════════════════════════════════════════
// Private widgets
// ═══════════════════════════════════════════════════════════════════

class _StatusStateBuilder<C extends StatusCubit<S>, S extends StatusState>
    extends StatelessWidget {
  final C? bloc;
  final Widget Function(BuildContext, S) onSuccess;
  final Widget Function(BuildContext, S, AppFailure?)? onError;
  final Widget Function(BuildContext, S)? onLoading;
  final Widget Function(BuildContext, S)? onInitial;
  final bool Function(S, S)? buildWhen;
  final void Function(BuildContext, S)? listener;

  const _StatusStateBuilder({
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
    return BlocConsumer<C, S>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) {
        return switch (state.status) {
          Status.init =>
            onInitial?.call(context, state) ?? const SizedBox.shrink(),
          Status.loading =>
            onLoading?.call(context, state) ?? const StateLoadingView(),
          Status.error =>
            onError?.call(context, state, state.failure) ??
                _DefaultErrorView<C>(bloc: bloc, failure: state.failure),
          Status.success => onSuccess(context, state),
        };
      },
    );
  }

  bool _defaultBuildWhen(S prev, S curr) => prev.status != curr.status;
}

class _DefaultErrorView<C> extends StatelessWidget {
  final C? bloc;
  final AppFailure? failure;

  const _DefaultErrorView({this.bloc, this.failure});

  @override
  Widget build(BuildContext context) {
    final cubit = bloc ?? context.read<C>();

    return StateErrorView(
      message: failure?.message ?? 'Неизвестная ошибка',
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
          AppBar(title: title != null ? Text(title!) : null, centerTitle: true),
      body: child,
      backgroundColor: backgroundColor,
    );
  }
}
