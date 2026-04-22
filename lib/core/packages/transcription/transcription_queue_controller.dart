import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';

/// Узкий control surface для UI и screen-scoped cubit'ов, работающих
/// с очередью транскрибации.
abstract interface class TranscriptionQueueController {
  Stream<TranscriptionQueueSnapshot> get snapshots;

  TranscriptionQueueSnapshot get current;

  Future<void> retry(String noteUid);

  Future<void> cancel(String noteUid);

  Future<void> retryAll();

  Future<void> cancelAll();

  Future<void> clearFailedAll();

  Future<void> dismissFailed(String noteUid);

  Future<void> retryBootstrap();

  Future<void> resumeAfterInterruptedRun();

  void resume();

  Future<void> dispose();
}
