import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/base_cubit.dart';
import 'package:voice_notes/core/state/initializable.dart';

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
