import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_state.dart';
import 'package:voice_notes/core/state/initializable.dart';
import 'package:voice_notes/core/state/state_views.dart';

/// Виджет для построения UI на основе BaseState
///
/// Обёртка над BlocBuilder с дефолтным buildWhen по runtimeType.
class BaseStateBuilder<C extends BlocBase<BaseState<S>>, S>
    extends StatelessWidget {
  /// Кубит (опционально, если не передан — берётся из контекста)
  final C? bloc;

  /// Обязательный колбэк для успешного состояния
  final Widget Function(BuildContext context, Success<S> state) onSuccess;

  /// Колбэк для ошибки (по умолчанию StateErrorView)
  final Widget Function(BuildContext context, AppFailure failure)? onError;

  /// Колбэк для загрузки (по умолчанию StateLoadingView)
  final Widget Function(BuildContext context)? onLoading;

  /// Колбэк для начального состояния (по умолчанию SizedBox.shrink)
  final Widget Function(BuildContext context)? onInitial;

  /// Контроль перестроения (по умолчанию: только при смене типа состояния)
  final bool Function(BaseState<S> previous, BaseState<S> current)? buildWhen;

  const BaseStateBuilder({
    required this.onSuccess,
    super.key,
    this.bloc,
    this.onError,
    this.onLoading,
    this.onInitial,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, BaseState<S>>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      builder: (context, state) => switch (state) {
        Initial() => onInitial?.call(context) ?? const SizedBox.shrink(),
        Loading() => onLoading?.call(context) ?? const StateLoadingView(),
        Error(:final failure) =>
          onError?.call(context, failure) ?? _buildDefaultError(context, failure),
        Success() => onSuccess(context, state),
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
