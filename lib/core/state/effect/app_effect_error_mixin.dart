import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';
import 'package:voice_notes/core/state/effect/common_effects.dart';
import 'package:voice_notes/core/state/effect/effect_mixin.dart';

/// Утилиты для показа ошибок через effect без переключения persistent state.
mixin AppEffectErrorMixin<S> on BaseCubit<S>, EffectMixin<BaseEffect> {
  void showErrorEffect(
    AppFailure failure, {
    BaseEffect Function(AppFailure failure)? errorEffect,
  }) {
    safeEmitEffect(errorEffect?.call(failure) ?? ShowErrorEffect(failure));
  }

  AppFailure handleEffectError(
    Object error,
    StackTrace stackTrace, {
    BaseEffect Function(AppFailure failure)? errorEffect,
  }) {
    final failure = logError(error, stackTrace);
    showErrorEffect(failure, errorEffect: errorEffect);

    return failure;
  }
}
