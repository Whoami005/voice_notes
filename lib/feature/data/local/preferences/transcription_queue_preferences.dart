import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TranscriptionQueueGuardState {
  runningTranscription('running_transcription'),
  pausedAfterInterruption('paused_after_interruption');

  const TranscriptionQueueGuardState(this.value);

  final String value;

  static TranscriptionQueueGuardState? fromValue(String? value) {
    for (final state in values) if (state.value == value) return state;
    return null;
  }
}

@singleton
class TranscriptionQueuePreferences {
  static const String _keyGuardState = 'transcription_queue.guard_state';

  final SharedPreferences _prefs;

  TranscriptionQueuePreferences(this._prefs);

  Future<TranscriptionQueueGuardState?> getGuardState() async {
    return TranscriptionQueueGuardState.fromValue(
      _prefs.getString(_keyGuardState),
    );
  }

  Future<void> markRunningTranscription() {
    return _prefs.setString(
      _keyGuardState,
      TranscriptionQueueGuardState.runningTranscription.value,
    );
  }

  Future<void> markPausedAfterInterruption() {
    return _prefs.setString(
      _keyGuardState,
      TranscriptionQueueGuardState.pausedAfterInterruption.value,
    );
  }

  Future<void> clearGuardState() {
    return _prefs.remove(_keyGuardState);
  }
}
