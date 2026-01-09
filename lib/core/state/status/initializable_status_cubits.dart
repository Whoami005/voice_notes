import 'package:voice_notes/core/state/effect/common_effects.dart';
import 'package:voice_notes/core/state/shared/initializable.dart';
import 'package:voice_notes/core/state/status/status_cubit.dart';
import 'package:voice_notes/core/state/status/status_state.dart';

/// [AppStatusCubit] с автоматическим вызовом init() в конструкторе.
abstract class InitializableStatusCubit<S extends StatusState>
    extends StatusCubit<S, AppEffect>
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

/// [AppStatusCubit] с автоматическим init() и методом refresh().
abstract class RefreshableStatusCubit<S extends StatusState>
    extends StatusCubit<S, AppEffect>
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
