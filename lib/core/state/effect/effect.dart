/// Effect pattern для one-shot событий в Cubit/Bloc.
///
/// Эффекты — это UI-события, которые не влияют на состояние:
/// диалоги, snackbar, навигация и т.д.
///
/// Основные компоненты:
/// - `EffectMixin` — mixin для добавления эффектов
/// - `EffectCubit` / `EffectBloc` — базовые классы
/// - `EffectListener` — виджет для подписки на эффекты
/// - `AppEffectListener` — готовый listener с обработкой AppEffect
/// - `AppEffect` — стандартные эффекты (ShowError, ShowSuccess)
library;

export 'app_effect_error_mixin.dart';
export 'app_effect_listener.dart';
export 'base_effect.dart';
export 'common_effects.dart';
export 'effect_base.dart';
export 'effect_bloc_observer.dart';
export 'effect_listener.dart';
export 'effect_mixin.dart';
