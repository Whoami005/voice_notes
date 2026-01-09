import 'package:flutter/material.dart';
import 'package:voice_notes/core/state/effect/common_effects.dart';
import 'package:voice_notes/core/state/effect/effect_listener.dart';
import 'package:voice_notes/core/state/effect/effect_mixin.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';

/// Готовый listener для обработки [AppEffect].
///
/// Автоматически показывает:
/// - [ErrorDialog] для [ShowErrorEffect]
/// - [SnackBar] для [ShowSuccessEffect]
///
/// ```dart
/// AppEffectListener<MyCubit>(
///   child: ...,
/// )
/// ```
class AppEffectListener<C extends EffectMixin<AppEffect>>
    extends StatelessWidget {
  /// Дочерний виджет
  final Widget child;

  const AppEffectListener({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return EffectListener<C, AppEffect>(listener: _handleEffect, child: child);
  }

  void _handleEffect(BuildContext context, AppEffect effect) {
    switch (effect) {
      case ShowErrorEffect(:final failure):
        ErrorDialog.showFromFailure(context, failure);
      case ShowSuccessEffect(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    }
  }
}
