import 'package:voice_notes/core/state/shared/initializable.dart';
import 'package:voice_notes/core/state/status_state/status_cubit.dart';
import 'package:voice_notes/core/state/status_state/status_state.dart';

/// StatusCubit с автоматическим вызовом init() в конструкторе.
abstract class InitializableStatusCubit<T extends StatusState>
    extends StatusCubit<T>
    implements Initializable {
  InitializableStatusCubit(super.initialState) {
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
}

/// StatusCubit с автоматическим init() и методом refresh().
abstract class RefreshableStatusCubit<T extends StatusState>
    extends StatusCubit<T>
    implements Refreshable {
  RefreshableStatusCubit(super.initialState) {
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
}
