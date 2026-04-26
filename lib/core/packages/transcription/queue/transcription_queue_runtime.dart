import 'package:voice_notes/core/collections/unique_queue.dart';
import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
import 'package:voice_notes/core/packages/transcription/transcription_circuit_breaker.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/feature/domain/enums/queue_runtime_reason.dart';

/// Mutable in-memory state of the transcription queue.
///
/// Database note status remains the source of truth; this object only tracks
/// runtime-only details that are not persisted: FIFO order, active task,
/// cooperative cancellation, breaker state, progress, and bootstrap phase.
final class TranscriptionQueueRuntime {
  final UniqueQueue<String> queue = UniqueQueue<String>();
  final Set<String> cancelRequested = <String>{};
  final Set<String> deletedInFlight = <String>{};
  final TranscriptionCircuitBreaker breaker = TranscriptionCircuitBreaker(
    threshold: 3,
  );

  QueueBootstrapState bootstrapState = const QueueBootstrapNotStarted();
  bool draining = false;
  bool asrReady = false;
  bool pausedAfterInterruptedRun = false;
  String? processing;
  AsrCancelToken? currentCancelToken;
  AsrTranscribeProgress? lastProgress;
  String? lastProgressNoteUid;
  bool processingSupportsInteractiveProgress = false;
  bool processingSupportsCancellation = false;
  TranscriptionQueueSnapshot? lastSnapshot;

  bool get canProcessQueuedWork =>
      !breaker.isPaused &&
      !pausedAfterInterruptedRun &&
      asrReady &&
      bootstrapState.isReady &&
      queue.isNotEmpty;

  TranscriptionQueueSnapshot get current => lastSnapshot ??= buildSnapshot();

  void resetTransientState() {
    queue.clear();
    cancelRequested.clear();
    deletedInFlight.clear();
    processing = null;
    draining = false;
    pausedAfterInterruptedRun = false;
    clearProcessingRuntime();
  }

  void clearProcessingRuntime([String? noteUid]) {
    currentCancelToken = null;
    processingSupportsInteractiveProgress = false;
    processingSupportsCancellation = false;

    if (noteUid != null && lastProgressNoteUid != noteUid) return;

    lastProgress = null;
    lastProgressNoteUid = null;
  }

  TranscriptionQueueSnapshot buildSnapshot() => TranscriptionQueueSnapshot(
    bootstrapState: bootstrapState,
    queued: List.unmodifiable(queue),
    processing: processing,
    cancelRequested: Set.unmodifiable(cancelRequested),
    runtimeReason: computeRuntimeReason(),
    processingProgress: lastProgressNoteUid == processing ? lastProgress : null,
    processingSupportsInteractiveProgress:
        processingSupportsInteractiveProgress,
    processingSupportsCancellation: processingSupportsCancellation,
  );

  /// Interrupted-run guard is more actionable than breaker state: users need
  /// to know auto-resume is intentionally blocked after a killed transcription.
  QueueRuntimeReason computeRuntimeReason() {
    if (pausedAfterInterruptedRun) {
      return QueueRuntimeReason.interruptedPreviousRun;
    }
    if (breaker.isPaused) return QueueRuntimeReason.breakerTripped;
    if (bootstrapState.isReady && !asrReady) {
      return QueueRuntimeReason.awaitingModel;
    }

    return QueueRuntimeReason.none;
  }
}
