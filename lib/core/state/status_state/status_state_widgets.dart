import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/shared/initializable.dart';
import 'package:voice_notes/core/state/shared/state_views.dart';
import 'package:voice_notes/core/state/status_state/status_state.dart';

/// Виджет для построения UI на основе StatusState.
class StatusStateBody<C extends BlocBase<S>, S extends StatusState>
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

  const StatusStateBody({
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
    return BlocConsumer<C, S>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) {
        return switch (state.status) {
          LogicStateStatus.init =>
            onInitial?.call(context, state) ?? const SizedBox.shrink(),
          LogicStateStatus.loading =>
            onLoading?.call(context, state) ?? const StateLoadingView(),
          LogicStateStatus.error =>
            onError?.call(context, state, state.failure) ??
                _buildDefaultError(context, state),
          LogicStateStatus.success => onSuccess(context, state),
        };
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, S state) {
    final cubit = bloc ?? context.read<C>();
    final failure = state.failure;

    return StateErrorView(
      message: failure?.message ?? 'Неизвестная ошибка',
      onRetry: cubit is Initializable ? (cubit as Initializable).init : null,
    );
  }

  bool _defaultBuildWhen(S prev, S curr) => prev.status != curr.status;
}

class StatusStateScaffold<C extends BlocBase<S>, S extends StatusState>
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
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<C, S>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) => switch (state.status) {
        LogicStateStatus.init =>
          onInitial?.call(context, state) ??
              _wrapWithScaffold(context, const SizedBox.shrink()),
        LogicStateStatus.loading =>
          onLoading?.call(context, state) ??
              _wrapWithScaffold(context, const StateLoadingView()),
        LogicStateStatus.error =>
          onError?.call(context, state, state.failure) ??
              _wrapWithScaffold(
                context,
                _buildDefaultError(context, state.failure),
              ),
        LogicStateStatus.success => onSuccess(context, state),
      },
    );
  }

  /// Оборачивает body в Scaffold с AppBar
  Widget _wrapWithScaffold(BuildContext context, Widget body) {
    return Scaffold(
      appBar:
          appBar ??
          AppBar(title: title != null ? Text(title!) : null, centerTitle: true),
      body: body,
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildDefaultError(BuildContext context, AppFailure? failure) {
    final cubit = bloc ?? context.read<C>();

    return StateErrorView(
      message: failure?.message ?? 'Неизвестная ошибка',
      onRetry: cubit is Initializable ? (cubit as Initializable).init : null,
    );
  }

  bool _defaultBuildWhen(S prev, S curr) =>
      prev.runtimeType != curr.runtimeType;
}
