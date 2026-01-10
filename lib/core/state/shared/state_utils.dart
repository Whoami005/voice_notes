import 'package:flutter/widgets.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';

/// Утилиты для работы с state виджетами.
abstract final class StateUtils {
  /// Обработчик эффектов с поддержкой [HandledEffect].
  ///
  /// Если [onEffect] передан — вызывает его.
  /// Иначе, если эффект реализует [HandledEffect] — вызывает `effect.handle()`.
  static void handleEffect(
    BuildContext context,
    BaseEffect effect, {
    void Function(BuildContext, BaseEffect)? onEffect,
  }) {
    if (onEffect != null) {
      onEffect(context, effect);
    } else if (effect is HandledEffect) {
      effect.handle(context);
    }
  }
}
