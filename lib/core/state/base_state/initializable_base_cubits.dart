import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_state/base_cubit.dart';
import 'package:voice_notes/core/state/shared/initializable.dart';

/// BaseCubit с автоматическим вызовом init() в конструкторе.
abstract class InitializableCubit<T> extends BaseCubit<T>
    implements Initializable {
  InitializableCubit([super.initialState]) {
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

/// BaseCubit с автоматическим init() и методом refresh().
abstract class RefreshableCubit<T> extends BaseCubit<T> implements Refreshable {
  RefreshableCubit([super.initialState]) {
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
