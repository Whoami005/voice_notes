import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'transcription_queue_state.dart';

/// Оркестратор жизненного цикла очереди транскрибации.
///
/// Запускает seed-фазу сервиса в `init()` безусловно (до готовности ASR),
/// чтобы публичный API очереди (`enqueue`/`cancel`/`retry`) был доступен
/// с первой секунды. Drain (реальная транскрибация) гейтится `_asrReady`
/// внутри самого сервиса; готовность модели UI читает напрямую из `AsrCubit`.
///
/// Единственный путь заметки в очередь: БД (status = queued) →
/// `NoteRepository.watchQueued` → `_onQueuedChanged` → `_service.enqueue`.
/// Никто не зовёт `enqueue` напрямую — поэтому расхождения между БД и
/// in-memory очередью невозможны by construction.
class TranscriptionQueueCubit extends BaseCubit<TranscriptionQueueState> {
  final TranscriptionQueueService _service;
  final NoteRepository _noteRepository;

  StreamSubscription<TranscriptionQueueSnapshot>? _snapshotSub;
  StreamSubscription<List<NoteEntity>>? _queuedSub;

  /// Идемпотентность seed'а при переключении модели (ASR эмитит true повторно).
  bool _seedStarted = false;

  TranscriptionQueueCubit({
    required TranscriptionQueueService service,
    required NoteRepository noteRepository,
  }) : _service = service,
       _noteRepository = noteRepository,
       super(TranscriptionQueueState(snapshot: service.current)) {
    init();
  }

  Future<void> init() async {
    _snapshotSub = _service.snapshots.listen((snapshot) {
      safeEmit(state.copyWith(snapshot: snapshot));
    });

    _queuedSub = _noteRepository.watchQueued().listen(
      _onQueuedChanged,
      onError: addError,
    );

    // Seed очереди поднимаем безусловно: start() ASR-независим (только БД +
    // подписки), а drain гейтится `_asrReady` внутри самого сервиса. Если
    // ждать ASR здесь — public API сервиса (enqueue/cancel/retry) виснет
    // на `_ready.future`, пока модель не выбрана.
    await _service.start();
    _seedStarted = true;

    safeEmit(state.copyWith(status: QueueStatus.ready));
  }

  Future<void> retry(String uid) async {
    if (state.status.isInitial) return;
    try {
      await _service.retry(uid);
    } catch (e, s) {
      logError(e, s);
    }
  }

  Future<void> cancel(String uid) async {
    if (state.status.isInitial) return;
    try {
      await _service.cancel(uid);
    } catch (e, s) {
      logError(e, s);
    }
  }

  void onResume() => _service.resume();

  // ==================== Internals ====================

  void _onQueuedChanged(List<NoteEntity> queued) {
    if (!_seedStarted) return;

    final snapshot = _service.current;
    final known = <String>{...snapshot.queued, ?snapshot.processing};

    for (final note in queued) {
      if (!known.contains(note.uuid)) {
        // enqueue идемпотентен; не await'им, чтобы не блокировать stream.
        unawaited(_service.enqueue(note.uuid));
      }
    }
  }

  @override
  Future<void> close() async {
    await _snapshotSub?.cancel();
    await _queuedSub?.cancel();
    return super.close();
  }
}
