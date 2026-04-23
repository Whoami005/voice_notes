import 'package:voice_notes/core/state/async/async_cubit.dart';
import 'package:voice_notes/core/state/shared/initializable.dart';

/// [AsyncCubit] с автоматическим вызовом init() в конструкторе.
abstract class InitializableAsyncCubit<T> extends AsyncCubit<T>
    implements Initializable {
  InitializableAsyncCubit([super.initialState]) {
    _autoInit();
  }

  Future<void> _autoInit() async {
    try {
      await init();
    } catch (e, s) {
      final failure = logError(e, s);
      emitError(failure);
    }
  }

  @override
  Future<void> refresh() async {
    try {
      await init();
    } catch (e, s) {
      addError(e, s);
    }
  }
}
