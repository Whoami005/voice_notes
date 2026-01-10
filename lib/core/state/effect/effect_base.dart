import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/core/state/core/cubit_mixin.dart';
import 'package:voice_notes/core/state/effect/effect_mixin.dart';

/// Cubit с поддержкой эффектов.
///
/// Наследует от [BaseCubit], поэтому имеет доступ к:
/// - [logError] — логирование ошибок
/// - [safeEmit] — безопасный emit
///
/// ```dart
/// class MyCubit extends EffectCubit<MyState, MyEffect> {
///   MyCubit() : super(MyState.initial());
///
///   void doSomething() {
///     emitEffect(ShowErrorEffect(failure));
///   }
/// }
/// ```
abstract class EffectCubit<State, Effect> extends BaseCubit<State>
    with EffectMixin<Effect> {
  EffectCubit(super.initialState);
}

/// Bloc с поддержкой эффектов.
///
/// Имеет доступ к утилитам из [CubitMixin]:
/// - [logError] — логирование ошибок
/// - [safeEmit] — безопасный emit
///
/// ```dart
/// class MyBloc extends EffectBloc<MyEvent, MyState, MyEffect> {
///   MyBloc() : super(MyState.initial()) {
///     on<SomeEvent>((event, emit) {
///       emitEffect(ShowSuccessEffect('Done'));
///     });
///   }
/// }
/// ```
abstract class EffectBloc<Event, State, Effect> extends Bloc<Event, State>
    with CubitMixin<State>, EffectMixin<Effect> {
  EffectBloc(super.initialState);
}
