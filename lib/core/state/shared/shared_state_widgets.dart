import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/shared/initializable.dart';
import 'package:voice_notes/core/state/shared/state_views.dart';

/// Scaffold обёртка для loading/error состояний.
class StateScaffoldWrapper extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final String? title;
  final Color? backgroundColor;
  final Widget child;

  const StateScaffoldWrapper({
    required this.child,
    super.key,
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

/// Стандартный виджет ошибки с возможностью retry.
class StateDefaultErrorView<C> extends StatelessWidget {
  final C? bloc;
  final AppFailure? failure;

  const StateDefaultErrorView({super.key, this.bloc, this.failure});

  @override
  Widget build(BuildContext context) {
    final cubit = bloc ?? context.read<C>();

    return StateErrorView(
      message: failure?.message ?? 'Неизвестная ошибка',
      onRetry: cubit is Initializable ? (cubit as Initializable).init : null,
    );
  }
}
