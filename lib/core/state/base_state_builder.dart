import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_state.dart';
import 'package:voice_notes/core/state/initializable.dart';
import 'package:voice_notes/core/state/state_views.dart';

/// Виджет для построения UI на основе BaseState
///
/// Обёртка над BlocBuilder с дефолтным buildWhen по runtimeType.
class BaseStateBody<C extends BlocBase<BaseState<S>>, S>
    extends StatelessWidget {
  /// Кубит (опционально, если не передан — берётся из контекста)
  final C? bloc;

  /// Обязательный колбэк для успешного состояния
  final Widget Function(BuildContext context, S state) onSuccess;

  /// Колбэк для ошибки (по умолчанию StateErrorView)
  final Widget Function(BuildContext context, AppFailure failure)? onError;

  /// Колбэк для загрузки (по умолчанию StateLoadingView)
  final Widget Function(BuildContext context)? onLoading;

  /// Колбэк для начального состояния (по умолчанию SizedBox.shrink)
  final Widget Function(BuildContext context)? onInitial;

  /// Контроль перестроения (по умолчанию: только при смене типа состояния)
  final bool Function(BaseState<S> previous, BaseState<S> current)? buildWhen;

  final void Function(BuildContext, BaseState<S>)? listener;

  const BaseStateBody({
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
    return BlocConsumer<C, BaseState<S>>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) => switch (state) {
        InitialState() => onInitial?.call(context) ?? const SizedBox.shrink(),
        LoadingState() => onLoading?.call(context) ?? const StateLoadingView(),
        ErrorState(:final failure) =>
          onError?.call(context, failure) ??
              _buildDefaultError(context, failure),
        SuccessState() => onSuccess(context, state.data),
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

  bool _defaultBuildWhen(BaseState<S> prev, BaseState<S> curr) =>
      prev.runtimeType != curr.runtimeType;
}

/// Виджет для построения экрана на основе BaseState.
///
/// Для loading/error/initial автоматически строится Scaffold с AppBar
/// (кнопка назад всегда доступна).
/// Для success — полная свобода: разработчик сам строит весь UI.
class BaseStateScaffold<C extends BlocBase<BaseState<S>>, S>
    extends StatelessWidget {
  /// Кубит (опционально, если не передан — берётся из контекста)
  final C? bloc;

  /// Кастомный AppBar (приоритет)
  final PreferredSizeWidget? appBar;

  /// Заголовок (если appBar не передан)
  final String? title;

  /// Цвет фона Scaffold
  final Color? backgroundColor;

  /// Билдер для success состояния (обязательный).
  /// Разработчик сам строит весь UI включая Scaffold.
  final Widget Function(BuildContext context, S data) onSuccess;

  /// Колбэк для ошибки (по умолчанию StateErrorView)
  final Widget Function(BuildContext context, AppFailure failure)? onError;

  /// Колбэк для загрузки (по умолчанию StateLoadingView)
  final Widget Function(BuildContext context)? onLoading;

  /// Колбэк для начального состояния (по умолчанию SizedBox.shrink)
  final Widget Function(BuildContext context)? onInitial;

  /// Контроль перестроения (по умолчанию: только при смене типа состояния)
  final bool Function(BaseState<S> previous, BaseState<S> current)? buildWhen;

  /// Listener для side-effects
  final void Function(BuildContext, BaseState<S>)? listener;

  const BaseStateScaffold({
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
    return BlocConsumer<C, BaseState<S>>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listener: listener ?? (_, _) {},
      builder: (context, state) => switch (state) {
        InitialState() =>
          onInitial?.call(context) ??
              _wrapWithScaffold(context, const SizedBox.shrink()),
        LoadingState() =>
          onLoading?.call(context) ??
              _wrapWithScaffold(context, const StateLoadingView()),
        ErrorState(:final failure) =>
          onError?.call(context, failure) ??
              _wrapWithScaffold(context, _buildDefaultError(context, failure)),
        SuccessState(:final data) => onSuccess(context, data),
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

  Widget _buildDefaultError(BuildContext context, AppFailure failure) {
    final cubit = bloc ?? context.read<C>();

    return StateErrorView(
      message: failure.message,
      onRetry: cubit is Initializable ? (cubit as Initializable).init : null,
    );
  }

  bool _defaultBuildWhen(BaseState<S> prev, BaseState<S> curr) =>
      prev.runtimeType != curr.runtimeType;
}
