import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/enums/queue_runtime_reason.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'queue_management_state.dart';

/// Screen-scoped cubit для `QueueManagementScreen`. Композирует пять
/// реактивных источников:
///
/// 1. `queueController.snapshots` — `bootstrapState` / `runtimeReason` / `cancelRequested`.
/// 2. `repo.watchTranscribing()` — текущая обрабатываемая заметка (0 или 1).
/// 3. `repo.watchQueued()` — очередь (createdAt ASC).
/// 4. `repo.watchFailed()` — провалившиеся.
/// 5. `repo.watchCancelled()` — отменённые.
///
/// Новые экшены (`deleteCancelled`, `deleteAllCancelled`, `retryAllCancelled`)
/// с per-uid изоляцией ошибок — провал одного элемента не прерывает остальные.
class QueueManagementCubit extends BaseCubit<QueueManagementState> {
  final NoteRepository _noteRepository;
  final TranscriptionQueueController _queueController;

  StreamSubscription<TranscriptionQueueSnapshot>? _snapshotSub;
  StreamSubscription<List<NoteEntity>>? _transcribingSub;
  StreamSubscription<List<NoteEntity>>? _queuedSub;
  StreamSubscription<List<NoteEntity>>? _failedSub;
  StreamSubscription<List<NoteEntity>>? _cancelledSub;

  QueueManagementCubit({
    required NoteRepository noteRepository,
    required TranscriptionQueueController queueController,
  }) : _noteRepository = noteRepository,
       _queueController = queueController,
       super(
         QueueManagementState(
           bootstrapState: queueController.current.bootstrapState,
           runtimeReason: queueController.current.runtimeReason,
           cancelRequested: {...queueController.current.cancelRequested},
         ),
       ) {
    _snapshotSub = _queueController.snapshots.listen(
      _onSnapshot,
      onError: addError,
    );
    _transcribingSub = _noteRepository.watchTranscribing().listen(
      (list) => safeEmit(
        state.copyWith(
          processing: list.isEmpty ? null : list.first,
          clearProcessing: list.isEmpty,
        ),
      ),
      onError: addError,
    );
    _queuedSub = _noteRepository.watchQueued().listen(
      (queued) => safeEmit(state.copyWith(queued: queued)),
      onError: addError,
    );
    _failedSub = _noteRepository.watchFailed().listen(
      (failed) => safeEmit(state.copyWith(failed: failed)),
      onError: addError,
    );
    _cancelledSub = _noteRepository.watchCancelled().listen(
      (cancelled) => safeEmit(state.copyWith(cancelled: cancelled)),
      onError: addError,
    );
  }

  void _onSnapshot(TranscriptionQueueSnapshot snapshot) {
    safeEmit(
      state.copyWith(
        bootstrapState: snapshot.bootstrapState,
        runtimeReason: snapshot.runtimeReason,
        cancelRequested: Set.of(snapshot.cancelRequested),
      ),
    );
  }

  /// Permanent-delete одной отменённой. `NoteRepository.delete` удаляет
  /// запись и связанный аудио-файл в транзакции.
  Future<void> deleteCancelled(String uid) async {
    try {
      await _noteRepository.delete(uid);
    } catch (error, stackTrace) {
      logError(error, stackTrace);
    }
  }

  /// Массовое permanent-delete. Последовательно (предсказуемый порядок
  /// эмитов `onDeleted`). Ошибки per-uid изолированы.
  Future<void> deleteAllCancelled() async {
    final snapshot = List.of(state.cancelled);
    if (snapshot.isEmpty) return;

    for (final note in snapshot) {
      try {
        await _noteRepository.delete(note.uuid);
      } catch (error, stackTrace) {
        logError(error, stackTrace);
      }
    }
  }

  /// Массовое ре-queue всех cancelled. Существующий `service.retry(uid)`
  /// уже умеет брать и failed, и cancelled.
  Future<void> retryAllCancelled() async {
    final snapshot = List.of(state.cancelled);
    if (snapshot.isEmpty) return;

    for (final note in snapshot) {
      try {
        await _queueController.retry(note.uuid);
      } catch (error, stackTrace) {
        logError(error, stackTrace);
      }
    }
  }

  @override
  Future<void> close() async {
    await _snapshotSub?.cancel();
    await _transcribingSub?.cancel();
    await _queuedSub?.cancel();
    await _failedSub?.cancel();
    await _cancelledSub?.cancel();
    return super.close();
  }
}
