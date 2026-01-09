import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/state/core/cubit_mixin.dart';
import 'package:voice_notes/core/state/effect/effect_base.dart';

/// Базовый Cubit с общими утилитами, но БЕЗ поддержки эффектов.
///
/// Используй когда нужен доступ к [logError], [safeEmit], [execute],
/// но не требуются one-shot эффекты.
///
/// Для cubit'а с эффектами используй [EffectCubit].
abstract class BaseCubit<S> extends Cubit<S> with CubitMixin<S> {
  BaseCubit(super.initialState);
}
