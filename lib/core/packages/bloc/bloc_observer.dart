import 'package:flutter_bloc/flutter_bloc.dart';

class BlocsObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);

    // print(
    //   'BLOC: ${bloc.runtimeType} -'
    //   '\n   CURRENTSTATE: ${change.currentState}'
    //   '\n'
    //   '\n   NEXTSTATE: ${change.nextState}',
    // );

    // AppLogs.info(
    //   msg: 'BLOC: ${bloc.runtimeType} -'
    //       '\n   CURRENTSTATE: ${change.currentState}'
    //       '\n'
    //       '\n   NEXTSTATE: ${change.nextState}',
    // );
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);

    // print('BLOC: ${bloc.runtimeType} - \n$transition');

    // AppLogs.info(msg: 'BLOC: ${bloc.runtimeType} - \n$transition');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);

    print(
      'BLOC: ${bloc.runtimeType} -'
      '\n   ERROR: $error'
      '\n'
      '\n   STACKTRACE: $stackTrace',
    );

    // AppLogs.error(
    //   msg: 'BLOC: ${bloc.runtimeType} -'
    //       '\n   ERROR: $error'
    //       '\n'
    //       '\n   STACKTRACE: $stackTrace',
    // );
  }
}
