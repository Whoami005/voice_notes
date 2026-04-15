import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/extensions/future_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'transcription_queue_state.dart';

/// Оркестратор жизненного цикла очереди транскрибации. Запускает seed-фазу
/// сервиса после готовности ASR и страхует race `createPending → enqueue`
/// через `NoteRepository.watchPending`.
class TranscriptionQueueCubit extends BaseCubit<TranscriptionQueueState> {
  final TranscriptionQueueService _service;
  final AsrService _asrService;
  final NoteRepository _noteRepository;

  StreamSubscription<TranscriptionQueueSnapshot>? _snapshotSub;
  StreamSubscription<bool>? _asrSub;
  StreamSubscription<List<NoteEntity>>? _pendingSub;

  /// Идемпотентность seed'а при переключении модели (ASR эмитит true повторно).
  bool _seedStarted = false;

  TranscriptionQueueCubit({
    required TranscriptionQueueService service,
    required AsrService asrService,
    required NoteRepository noteRepository,
  }) : _service = service,
       _asrService = asrService,
       _noteRepository = noteRepository,
       super(TranscriptionQueueState(snapshot: service.current)) {
    init();
  }

  Future<void> init() async {
    _snapshotSub = _service.snapshots.listen((snapshot) {
      safeEmit(state.copyWith(snapshot: snapshot));
    });

    _pendingSub = _noteRepository.watchPending().listen(
      _onPendingChanged,
      onError: addError,
    );

    _asrSub = _asrService.stateStream.listen(
      _onAsrReadinessChanged,
      onError: addError,
    );

    if (_asrService.isInitialized) {
      await _onAsrReadinessChanged(true);
    } else {
      safeEmit(state.copyWith(status: QueueStatus.waitingForModel));
    }
  }

  Future<void> retry(String uid) async {
    if (state.status == QueueStatus.initial) return;
    try {
      await _service.retry(uid);
    } catch (e, s) {
      logError(e, s);
    }
  }

  Future<void> cancel(String uid) async {
    if (state.status == QueueStatus.initial) return;
    try {
      await _service.cancel(uid);
    } catch (e, s) {
      logError(e, s);
    }
  }

  void onResume() {
    if (state.status != QueueStatus.ready) return;
    _service.resume();
  }

  // ==================== Internals ====================

  Future<void> _onAsrReadinessChanged(bool isReady) async {
    if (!isReady) {
      // Seed уже мог пройти — не откатываем оркестратор в init, но UI
      // показывает «ждём модель», пока ASR не вернётся.
      if (state.status == QueueStatus.initializing) return;
      safeEmit(state.copyWith(status: QueueStatus.waitingForModel));
      return;
    }

    if (_seedStarted) {
      if (state.status != QueueStatus.ready) {
        safeEmit(state.copyWith(status: QueueStatus.ready));
      }
      return;
    }

    _seedStarted = true;
    safeEmit(state.copyWith(status: QueueStatus.initializing));

    // start() best-effort: ошибки логируются внутри сервиса; per-note
    // сбои уже отражены в статусах заметок.
    await _service.start().atLeast();

    safeEmit(state.copyWith(status: QueueStatus.ready));
  }

  void _onPendingChanged(List<NoteEntity> pending) {
    if (!_seedStarted) return;

    final snapshot = _service.current;
    final known = <String>{...snapshot.pending, ?snapshot.processing};

    for (final note in pending) {
      if (!known.contains(note.uuid)) {
        // enqueue идемпотентен; не await'им, чтобы не блокировать stream.
        unawaited(_service.enqueue(note.uuid));
      }
    }
  }

  @override
  Future<void> close() async {
    await _snapshotSub?.cancel();
    await _asrSub?.cancel();
    await _pendingSub?.cancel();
    return super.close();
  }
}
