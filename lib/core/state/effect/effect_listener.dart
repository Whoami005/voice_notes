import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/state/effect/effect_mixin.dart';

/// Listener для подписки на эффекты из Cubit/Bloc.
///
/// Используйте вместе с BlocListener для полноценной подписки:
/// ```dart
/// MultiBlocListener(
///   listeners: [
///     BlocListener<MyCubit, MyState>(...),
///     EffectListener<MyCubit, MyEffect>(listener: ...),
///   ],
///   child: ...,
/// )
/// ```
class EffectListener<C extends EffectMixin<E>, E> extends StatefulWidget {
  /// Дочерний виджет
  final Widget child;

  /// Callback при получении эффекта
  final void Function(BuildContext context, E effect) listener;

  /// Опциональный cubit (если не предоставлен, берётся из context)
  final C? bloc;

  const EffectListener({
    required this.child,
    required this.listener,
    this.bloc,
    super.key,
  });

  @override
  State<EffectListener<C, E>> createState() => _EffectListenerState<C, E>();
}

class _EffectListenerState<C extends EffectMixin<E>, E>
    extends State<EffectListener<C, E>> {
  StreamSubscription<E>? _subscription;
  late C _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.bloc ?? context.read<C>();
    _subscribe();
  }

  @override
  void didUpdateWidget(EffectListener<C, E> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldCubit = oldWidget.bloc ?? context.read<C>();
    final newCubit = widget.bloc ?? oldCubit;

    if (oldCubit != newCubit) {
      _unsubscribe();
      _cubit = newCubit;
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = widget.bloc ?? context.read<C>();

    if (_cubit != cubit) {
      _unsubscribe();
      _cubit = cubit;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = _cubit.effects.listen((effect) {
      if (mounted) widget.listener(context, effect);
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
