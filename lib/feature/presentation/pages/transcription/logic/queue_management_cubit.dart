import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'queue_management_state.dart';

/// Screen-scoped cubit для экрана управления очередью. Подписан на
/// `watchFailed` / `watchCancelled` — реактивно ведёт UI-списки. Действия
/// (retryAll / clearFailedAll / retry / dismiss) не делает сам — их
/// проксирует `TranscriptionQueueCubit` (queue owner).
class QueueManagementCubit extends BaseCubit<QueueManagementState> {
  final NoteRepository _noteRepository;

  StreamSubscription<List<NoteEntity>>? _failedSub;
  StreamSubscription<List<NoteEntity>>? _cancelledSub;

  QueueManagementCubit({required NoteRepository noteRepository})
    : _noteRepository = noteRepository,
      super(const QueueManagementState()) {
    _failedSub = _noteRepository.watchFailed().listen(
      (failed) => safeEmit(state.copyWith(failed: failed)),
      onError: addError,
    );
    _cancelledSub = _noteRepository.watchCancelled().listen(
      (cancelled) => safeEmit(state.copyWith(cancelled: cancelled)),
      onError: addError,
    );
  }

  @override
  Future<void> close() async {
    await _failedSub?.cancel();
    await _cancelledSub?.cancel();
    return super.close();
  }
}
