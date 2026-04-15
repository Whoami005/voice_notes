import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/extensions/string_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

/// FIFO-диспетчер очереди транскрибации. Source of truth по статусам — БД;
/// очередь хранит только порядок обработки.
///
/// Гейт drain'а — `_asrReady`: пока модель не готова, заметки копятся в
/// `_pending`, но не фейлятся с `noModelSelected`. См. `docs/transcription_queue_flow.md`.
@Singleton()
class TranscriptionQueueService {
  /// Порог circuit breaker: сколько подряд провалов переводит очередь
  /// на паузу. Пауза снимается явным `retry()` от пользователя.
  static const int _circuitBreakerThreshold = 3;

  /// Максимальное время на одну транскрибацию. Защищает от зависания
  /// sherpa-onnx FFI внутри изолята — таймаут переводит заметку в failed
  /// с `transcriptionFailed`, очередь продолжает работать.
  static const Duration _transcribeTimeout = Duration(minutes: 30);

  final NoteRepository _noteRepository;
  final AsrService _asrService;
  final RecordingPreferences _preferences;

  final Queue<String> _pending = Queue<String>();
  final Set<String> _enqueued = <String>{};
  final Set<String> _cancelled = <String>{};
  String? _processing;
  bool _draining = false;
  int _consecutiveFailures = 0;
  bool _paused = false;
  bool _asrReady = false;

  /// Сигнализирует, что [start] завершил seed из БД и подписку на onDeleted.
  /// Все публичные методы ждут этот completer, чтобы исключить race с UI,
  /// который успел вызвать `enqueue` до окончания старта.
  final Completer<void> _ready = Completer<void>();

  StreamSubscription<String>? _deleteSub;
  StreamSubscription<bool>? _asrSub;

  final StreamController<TranscriptionQueueSnapshot> _snapshots =
      StreamController<TranscriptionQueueSnapshot>.broadcast();

  TranscriptionQueueSnapshot? _lastSnapshot;

  TranscriptionQueueService({
    required NoteRepository noteRepository,
    required AsrService asrService,
    required RecordingPreferences preferences,
  }) : _noteRepository = noteRepository,
       _asrService = asrService,
       _preferences = preferences;

  // ==================== Public API ====================

  Stream<TranscriptionQueueSnapshot> get snapshots => _snapshots.stream;

  TranscriptionQueueSnapshot get current => _lastSnapshot ??= _buildSnapshot();

  /// Вызывается только в тестах и при полной реинициализации. В проде
  /// сервис живёт всю сессию как `@Singleton`.
  Future<void> dispose() async {
    await _deleteSub?.cancel();
    _deleteSub = null;
    await _asrSub?.cancel();
    _asrSub = null;
    if (!_snapshots.isClosed) await _snapshots.close();
  }

  /// Cold-start recovery + запуск дренажа. Вызывается ровно один раз.
  /// На resume использовать [resume].
  Future<void> start() async {
    try {
      _asrReady = _asrService.isInitialized;
      _asrSub ??= _asrService.stateStream.listen(_onAsrReadyChanged);

      await _noteRepository.resetTranscribingToQueued();
      final pending = await _noteRepository.getPending();

      // audio == null обработает _processOne → failTranscription. Заранее
      // фейлить здесь — N лишних транзакций на seed.
      for (final note in pending) {
        if (!_enqueued.contains(note.uuid) && _processing != note.uuid) {
          _pending.add(note.uuid);
          _enqueued.add(note.uuid);
        }
      }

      _deleteSub ??= _noteRepository.onDeleted.listen(_onNoteDeleted);
    } catch (e, s) {
      developer.log(
        'TranscriptionQueueService.start failed',
        error: e,
        stackTrace: s,
        name: 'TranscriptionQueue',
      );
    } finally {
      if (!_ready.isCompleted) _ready.complete();
      _emitSnapshot();
    }

    unawaited(_drain());
  }

  /// Lifecycle resume: пнуть дренаж без тяжёлого recovery. Безопасен на
  /// каждый foreground-event — не трогает БД и не пересоздаёт подписки.
  void resume() {
    if (!_ready.isCompleted || _paused) return;
    unawaited(_drain());
  }

  /// Идемпотентно: повторный enqueue того же uid игнорируется.
  Future<void> enqueue(String uid) async {
    await _ready.future;
    if (_enqueued.contains(uid) || _processing == uid) return;

    _pending.add(uid);
    _enqueued.add(uid);
    _emitSnapshot();

    unawaited(_drain());
  }

  /// User-action — сбрасывает circuit breaker и пауза. Silent no-op,
  /// если заметка не в failed/cancelled.
  Future<void> retry(String uid) async {
    await _ready.future;

    final note = await _noteRepository.getByUidOrNull(uid);
    if (note == null || !(note.isFailed || note.isCancelled)) return;

    _paused = false;
    _consecutiveFailures = 0;
    _cancelled.remove(uid);

    await _noteRepository.markQueued(uid);

    if (!_enqueued.contains(uid) && _processing != uid) {
      _pending.add(uid);
      _enqueued.add(uid);
    }
    _emitSnapshot();

    unawaited(_drain());
  }

  /// Отмена без удаления заметки. Для in-flight uid `_processOne` после
  /// завершения ASR увидит флаг в `_cancelled` и вызовет markCancelled сам.
  Future<void> cancel(String uid) async {
    await _ready.future;

    final wasPending = _pending.remove(uid);
    _enqueued.remove(uid);

    if (wasPending) {
      await _noteRepository.markCancelled(uid);
      _emitSnapshot();
      return;
    }

    if (_processing == uid) {
      _cancelled.add(uid);
      _emitSnapshot();
    }
  }

  // ==================== Internals ====================

  Future<void> _drain() async {
    await _ready.future;
    if (_draining || _paused || !_asrReady) return;

    _draining = true;
    try {
      while (_pending.isNotEmpty) {
        if (!_asrReady) break;

        if (_consecutiveFailures >= _circuitBreakerThreshold) {
          _paused = true;
          _emitSnapshot();

          developer.log(
            'TranscriptionQueue paused after $_circuitBreakerThreshold '
            'consecutive failures',
            name: 'TranscriptionQueue',
          );
          break;
        }

        final uid = _pending.removeFirst();
        _enqueued.remove(uid);
        _processing = uid;
        _emitSnapshot();

        await _processOne(uid);

        _processing = null;
        _emitSnapshot();
      }
    } finally {
      _draining = false;
      _emitSnapshot();
    }
  }

  Future<void> _processOne(String uid) async {
    try {
      final note = await _noteRepository.getByUidOrNull(uid);
      if (note == null) return;

      if (_cancelled.remove(uid)) {
        await _noteRepository.markCancelled(uid);
        return;
      }

      final audio = note.audio;
      if (audio == null) {
        await _noteRepository.failTranscription(
          uid: uid,
          reason: TranscriptionFailureReason.audioFileMissing,
        );
        _consecutiveFailures++;
        return;
      }

      final modelName = _asrService.currentModel?.name ?? '';
      await _noteRepository.markTranscribing(uid);

      // TODO(perf): прервать in-flight ASR при cancel/delete, не дожидаясь
      //   завершения транскрибации.
      final abs = await _resolveAudioAbsolutePath(audio);
      final asrResult = await _asrService
          .transcribeFile(abs)
          .timeout(
            _transcribeTimeout,
            onTimeout: () => throw const AsrProcessingException(
              'ASR transcription timed out',
            ),
          );

      // Пользователь мог удалить или отменить заметку за время await —
      // отбрасываем результат. Для cancelled — явно ставим статус.
      if (_cancelled.remove(uid)) {
        await _noteRepository.markCancelled(uid);
        return;
      }

      await _noteRepository.completeTranscription(
        uid: uid,
        text: asrResult.text,
        language: asrResult.detectedLanguage ?? '',
        modelName: modelName,
        wordCount: asrResult.text.wordCount,
        deleteAudio: !_preferences.keepOriginals,
      );
      _consecutiveFailures = 0;
    } catch (e, s) {
      developer.log(
        'TranscriptionQueueService._processOne failed for $uid',
        error: e,
        stackTrace: s,
        name: 'TranscriptionQueue',
      );

      final reason = _classifyFailure(e);
      await _noteRepository.failTranscription(uid: uid, reason: reason);
      _consecutiveFailures++;
    }
  }

  void _onAsrReadyChanged(bool value) {
    if (_asrReady == value) return;
    _asrReady = value;
    if (value) unawaited(_drain());
  }

  void _onNoteDeleted(String uid) {
    // В _cancelled кладём только in-flight uid: из `_pending` он уже
    // удалён и `_processOne` его не увидит, поэтому метки cancel не требует.
    if (_pending.remove(uid)) {
      _enqueued.remove(uid);
    } else if (_processing == uid) {
      _cancelled.add(uid);
    }
    _emitSnapshot();
  }

  TranscriptionFailureReason _classifyFailure(Object e) => switch (e) {
    AsrNotInitializedException() => TranscriptionFailureReason.noModelSelected,
    AsrModelNotFoundException() => TranscriptionFailureReason.modelLoadFailed,
    AsrInvalidAudioException() => TranscriptionFailureReason.audioFileCorrupted,
    AsrProcessingException() => TranscriptionFailureReason.transcriptionFailed,
    FileSystemException() => TranscriptionFailureReason.audioFileMissing,
    _ => TranscriptionFailureReason.unknown,
  };

  Future<String> _resolveAudioAbsolutePath(NoteAudioEntity audio) {
    return AudioPaths.resolveRelativePath(audio.relativePath);
  }

  TranscriptionQueueSnapshot _buildSnapshot() => TranscriptionQueueSnapshot(
    pending: List.unmodifiable(_pending),
    processing: _processing,
    paused: _paused,
  );

  void _emitSnapshot() {
    if (_snapshots.isClosed) return;

    final next = _buildSnapshot();
    if (_lastSnapshot == next) return;

    _lastSnapshot = next;
    _snapshots.add(next);
  }
}
