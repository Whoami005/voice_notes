import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/state/effect/effect_bloc_observer.dart';

class BlocsObserver extends EffectBlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);

    // print(
    //   'BLOC: ${bloc.runtimeType} -'
    //   '\n   CURRENTSTATE: ${change.currentState}'
    //   '\n'
    //   '\n   NEXTSTATE: ${change.nextState}',
    // );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);

    // print('BLOC: ${bloc.runtimeType} - \n$transition');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);

    if (kDebugMode) {
      debugPrint(
        'BLOC ERROR: ${bloc.runtimeType} -'
        '\n   ERROR: $error'
        '\n'
        '\n   STACKTRACE: $stackTrace',
      );
    }
  }

  @override
  void onEffect(Closable bloc, Object effect) {
    super.onEffect(bloc, effect);

    if (kDebugMode) {
      debugPrint('EFFECT: ${bloc.runtimeType} - $effect');
    }
  }
}
