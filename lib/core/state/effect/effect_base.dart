import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/state/effect/effect_mixin.dart';

/// Cubit с поддержкой эффектов.
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
abstract class EffectCubit<State, Effect> extends Cubit<State>
    with EffectMixin<Effect> {
  EffectCubit(super.initialState);
}

/// Bloc с поддержкой эффектов.
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
    with EffectMixin<Effect> {
  EffectBloc(super.initialState);
}
