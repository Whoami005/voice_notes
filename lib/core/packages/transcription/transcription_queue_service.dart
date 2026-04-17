import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/collections/unique_queue.dart';
import 'package:voice_notes/core/extensions/string_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
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
/// `_queue`, но не фейлятся с `noModelSelected`. См. `docs/transcription_queue_flow.md`.
@Singleton()
class TranscriptionQueueService {
  TranscriptionQueueService({
    required NoteRepository noteRepository,
    required AsrService asrService,
    required RecordingPreferences preferences,
  }) : _noteRepository = noteRepository,
       _asrService = asrService,
       _preferences = preferences;

  /// Максимальное время на одну транскрибацию. Защищает от зависания
  /// sherpa-onnx FFI внутри изолята — таймаут переводит заметку в failed
  /// с `transcriptionFailed`, очередь продолжает работать.
  static const Duration _transcribeTimeout = Duration(minutes: 30);

  final NoteRepository _noteRepository;
  final AsrService _asrService;
  final RecordingPreferences _preferences;
  final UniqueQueue<String> _queue = UniqueQueue<String>();
  final Set<String> _cancelled = <String>{};

  /// 3 подряд провала → пауза. Снимается только явным `retry()`.
  final _CircuitBreaker _breaker = _CircuitBreaker(3);

  /// Сигнализирует, что [start] прошёл seed из БД и подписался на `onDeleted`.
  /// Публичные методы (`enqueue`, `cancel`, `retry`) ждут этот completer, чтобы
  /// первый `_drain()` увидел объединённое множество uid: in-memory + seed.
  ///
  /// ASR-готовность здесь не при чём: `start()` вызывается безусловно из
  /// `TranscriptionQueueCubit.init()` (до готовности модели), drain гейтится
  /// отдельным флагом `_asrReady`.
  final Completer<void> _ready = Completer<void>();
  final StreamController<TranscriptionQueueSnapshot> _snapshotController =
      StreamController<TranscriptionQueueSnapshot>.broadcast();

  bool _draining = false;
  bool _asrReady = false;
  String? _processing;
  StreamSubscription<String>? _noteDeletedSub;
  StreamSubscription<bool>? _asrReadySub;
  TranscriptionQueueSnapshot? _lastSnapshot;

  Stream<TranscriptionQueueSnapshot> get snapshots =>
      _snapshotController.stream;

  TranscriptionQueueSnapshot get current => _lastSnapshot ??= _buildSnapshot();

  bool get _canStartDrain => !_draining && !_breaker.isPaused && _asrReady;

  /// Вызывается только в тестах и при полной реинициализации. В проде
  /// сервис живёт всю сессию как `@Singleton`.
  Future<void> dispose() async {
    await _noteDeletedSub?.cancel();
    _noteDeletedSub = null;
    await _asrReadySub?.cancel();
    _asrReadySub = null;

    if (!_snapshotController.isClosed) {
      await _snapshotController.close();
    }
  }

  /// Cold-start recovery + запуск дренажа. Вызывается ровно один раз.
  /// На resume использовать [resume].
  Future<void> start() async {
    try {
      _asrReady = _asrService.isInitialized;
      _asrReadySub ??= _asrService.stateStream.listen(_onAsrReadyChanged);

      await _recoverQueuedNotes();

      _noteDeletedSub ??= _noteRepository.onDeleted.listen(_onNoteDeleted);
    } catch (error, stackTrace) {
      developer.log(
        'TranscriptionQueueService.start failed',
        error: error,
        stackTrace: stackTrace,
        name: 'TranscriptionQueue',
      );
    } finally {
      if (!_ready.isCompleted) _ready.complete();
      _emitSnapshot();
    }

    _scheduleDrain();
  }

  /// Lifecycle resume: пнуть дренаж без тяжёлого recovery. Безопасен на
  /// каждый foreground-event — не трогает БД и не пересоздаёт подписки.
  void resume() {
    if (!_ready.isCompleted || _breaker.isPaused) return;
    _scheduleDrain();
  }

  Future<void> enqueue(String noteUid) async {
    await _ready.future;
    if (_processing == noteUid || !_queue.add(noteUid)) return;

    _emitSnapshot();
    _scheduleDrain();
  }

  /// User-action: снимает pause и возвращает failed/cancelled заметку в очередь.
  /// Silent no-op, если заметка не в failed/cancelled.
  Future<void> retry(String noteUid) async {
    await _ready.future;

    final note = await _noteRepository.getByUidOrNull(noteUid);
    if (note == null || !(note.isFailed || note.isCancelled)) return;

    _breaker.reset();
    _cancelled.remove(noteUid);

    await _noteRepository.markQueued(noteUid);

    if (_processing != noteUid) _queue.add(noteUid);
    _emitSnapshot();

    _scheduleDrain();
  }

  /// Отмена без удаления заметки. Для in-flight uid `_processOne` после
  /// завершения ASR увидит флаг в `_cancelled` и вызовет `markCancelled` сам.
  Future<void> cancel(String noteUid) async {
    await _ready.future;

    if (_queue.remove(noteUid)) {
      await _noteRepository.markCancelled(noteUid);
      _emitSnapshot();
      return;
    }

    if (_processing == noteUid) _cancelled.add(noteUid);
    _emitSnapshot();
  }

  Future<void> _recoverQueuedNotes() async {
    await _noteRepository.resetTranscribingToQueued();
    final queuedNotes = await _noteRepository.getQueued();

    // audio == null обработает _processOne → failTranscription. Заранее
    // фейлить здесь — N лишних транзакций на seed.
    for (final note in queuedNotes) _queue.add(note.uuid);
  }

  void _scheduleDrain() => unawaited(_drain());

  Future<void> _drain() async {
    await _ready.future;
    if (!_canStartDrain) return;

    _draining = true;
    try {
      while (_queue.isNotEmpty) {
        if (!_asrReady || _breaker.isPaused) break;

        final noteUid = _queue.removeFirst();
        _processing = noteUid;
        _emitSnapshot();

        await _processOne(noteUid);

        _processing = null;
        _emitSnapshot();
      }

      if (_breaker.isPaused) {
        developer.log(
          'TranscriptionQueue paused after consecutive failures',
          name: 'TranscriptionQueue',
        );
      }
    } finally {
      _draining = false;
      _emitSnapshot();
    }
  }

  Future<void> _processOne(String noteUid) async {
    try {
      final note = await _noteRepository.getByUidOrNull(noteUid);
      if (note == null) return;

      if (await _consumeCancellation(noteUid)) return;

      final audio = note.audio;
      if (audio == null) {
        await _failWithReason(
          noteUid,
          TranscriptionFailureReason.audioFileMissing,
        );
        return;
      }

      final modelName = _asrService.currentModel?.name ?? '';
      await _noteRepository.markTranscribing(noteUid);

      // TODO(perf): прервать in-flight ASR при cancel/delete, не дожидаясь
      //   завершения транскрибации.
      final result = await _transcribeWithTimeout(audio);

      // Пользователь мог удалить или отменить заметку за время await —
      // отбрасываем результат. Для cancelled — явно ставим статус.
      if (await _consumeCancellation(noteUid)) return;

      await _noteRepository.completeTranscription(
        uid: noteUid,
        text: result.text,
        language: result.detectedLanguage ?? '',
        modelName: modelName,
        wordCount: result.text.wordCount,
        deleteAudio: !_preferences.keepOriginals,
      );
      _breaker.recordSuccess();
    } catch (error, stackTrace) {
      await _handleProcessingFailure(noteUid, error, stackTrace);
    }
  }

  Future<bool> _consumeCancellation(String noteUid) async {
    if (!_cancelled.remove(noteUid)) return false;

    await _noteRepository.markCancelled(noteUid);
    return true;
  }

  Future<AsrResult> _transcribeWithTimeout(NoteAudioEntity audio) async {
    final absolutePath = await _resolveAudioAbsolutePath(audio);

    return _asrService
        .transcribeFile(absolutePath)
        .timeout(
          _transcribeTimeout,
          onTimeout: () =>
              throw const AsrProcessingException('ASR transcription timed out'),
        );
  }

  Future<void> _failWithReason(
    String noteUid,
    TranscriptionFailureReason reason,
  ) async {
    await _noteRepository.failTranscription(uid: noteUid, reason: reason);
    _breaker.recordFailure();
  }

  Future<void> _handleProcessingFailure(
    String noteUid,
    Object error,
    StackTrace stackTrace,
  ) async {
    developer.log(
      'TranscriptionQueueService._processOne failed for $noteUid',
      error: error,
      stackTrace: stackTrace,
      name: 'TranscriptionQueue',
    );

    final reason = _classifyFailure(error);
    await _noteRepository.failTranscription(uid: noteUid, reason: reason);
    _breaker.recordFailure();
  }

  void _onAsrReadyChanged(bool ready) {
    if (_asrReady == ready) return;

    _asrReady = ready;
    if (ready) _scheduleDrain();
  }

  void _onNoteDeleted(String noteUid) {
    // В _cancelled кладём только in-flight uid: из `_queue` он уже
    // удалён и `_processOne` его не увидит, поэтому метки cancel не требует.
    if (!_queue.remove(noteUid) && _processing == noteUid) {
      _cancelled.add(noteUid);
    }

    _emitSnapshot();
  }

  TranscriptionFailureReason _classifyFailure(Object error) => switch (error) {
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
    queued: List.unmodifiable(_queue),
    processing: _processing,
    paused: _breaker.isPaused,
  );

  void _emitSnapshot() {
    if (_snapshotController.isClosed) return;

    final nextSnapshot = _buildSnapshot();
    if (_lastSnapshot == nextSnapshot) return;

    _lastSnapshot = nextSnapshot;
    _snapshotController.add(nextSnapshot);
  }
}

/// Circuit breaker для очереди: считает подряд проваленные попытки,
/// при достижении порога ставит [isPaused] в `true`. Снимается через
/// [reset] (вызывается из `retry()`).
final class _CircuitBreaker {
  _CircuitBreaker(this._threshold);

  final int _threshold;
  int _consecutive = 0;
  bool _paused = false;

  bool get isPaused => _paused;

  void recordSuccess() {
    _consecutive = 0;
  }

  void recordFailure() {
    _consecutive++;
    if (_consecutive >= _threshold) _paused = true;
  }

  void reset() {
    _consecutive = 0;
    _paused = false;
  }
}
