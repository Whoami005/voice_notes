import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
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
