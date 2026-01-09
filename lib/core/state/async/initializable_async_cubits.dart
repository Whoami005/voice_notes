import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/async/async_cubit.dart';
import 'package:voice_notes/core/state/shared/initializable.dart';

/// [AppAsyncCubit] с автоматическим вызовом init() в конструкторе.
abstract class InitializableAsyncCubit<T, E> extends AsyncCubit<T, E>
    implements Initializable {
  InitializableAsyncCubit([super.initialState]) {
    _autoInit();
  }

  Future<void> _autoInit() async {
    try {
      await init();
    } catch (e, s) {
      addError(e, s);
      emitError(AppFailure.from(e, s));
    }
  }
}

/// [AppAsyncCubit] с автоматическим init() и методом refresh().
abstract class RefreshableAsyncCubit<T, E> extends AsyncCubit<T, E>
    implements Refreshable {
  RefreshableAsyncCubit([super.initialState]) {
    _autoInit();
  }

  Future<void> _autoInit() async {
    try {
      await init();
    } catch (e, s) {
      addError(e, s);
      emitError(AppFailure.from(e, s));
    }
  }
}
