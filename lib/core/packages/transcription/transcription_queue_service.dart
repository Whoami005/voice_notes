import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/collections/unique_queue.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/extensions/string_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/transcription/transcription_circuit_breaker.dart';
import 'package:voice_notes/core/packages/transcription/transcription_failure_classifier.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/enums/queue_runtime_reason.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

/// FIFO-диспетчер очереди транскрибации и единственный владелец queue domain.
///
/// Source of truth по статусам — БД. Сервис подписан на
/// `NoteRepository.watchQueued`, сам подхватывает новые заметки и
/// выполняет их через ASR. Продюсеры (например, `RecordingCubit`) пишут
/// заметку в БД со статусом `queued` — сервис увидит это через stream
/// и не требует явного `enqueue`.
///
/// Gate drain'а — `_asrReady`: пока модель не готова, заметки копятся в
/// `_queue`, но не фейлятся с `noModelSelected`. Bootstrap — через
/// `@PostConstruct()` injectable: сервис self-bootstrap'ится при первом
/// разрешении DI, AppInitializer не участвует.
///
/// `start()` **не бросает**: любой сбой переводит `bootstrapState` в
/// `error(failure)`; UI может вызвать `retryBootstrap()`.
@Singleton()
class TranscriptionQueueService {
  TranscriptionQueueService({
    required NoteRepository noteRepository,
    required AsrService asrService,
    required RecordingPreferences preferences,
  }) : _noteRepository = noteRepository,
       _asrService = asrService,
       _preferences = preferences,
       _transcribeTimeout = const Duration(minutes: 30);

  /// Тест-only конструктор. Даёт возможность подставить короткий таймаут
  /// в unit-тестах без регистрации отдельной `Duration` в DI.
  @visibleForTesting
  TranscriptionQueueService.forTesting({
    required NoteRepository noteRepository,
    required AsrService asrService,
    required RecordingPreferences preferences,
    required Duration transcribeTimeout,
  }) : _noteRepository = noteRepository,
       _asrService = asrService,
       _preferences = preferences,
       _transcribeTimeout = transcribeTimeout;

  final NoteRepository _noteRepository;
  final AsrService _asrService;
  final RecordingPreferences _preferences;

  /// Максимальное время на одну транскрибацию. Защищает от зависания
  /// sherpa-onnx FFI внутри изолята — таймаут переводит заметку в failed
  /// с `transcriptionTimedOut`, очередь продолжает работать.
  final Duration _transcribeTimeout;

  final UniqueQueue<String> _queue = UniqueQueue<String>();

  /// User-initiated cancel для in-flight заметки. Показывается в snapshot,
  /// по завершении ASR пишется `markCancelled`.
  final Set<String> _cancelRequested = <String>{};

  /// Удаление заметки во время её транскрибации. По завершении ASR
  /// результат отбрасывается, в БД ничего не пишется (заметки уже нет).
  final Set<String> _deletedInFlight = <String>{};

  /// 3 подряд провала → pause. Автоматически снимается при появлении
  /// ASR-ready или пользовательским retry().
  final TranscriptionCircuitBreaker _breaker = TranscriptionCircuitBreaker(
    threshold: 3,
  );

  final StreamController<TranscriptionQueueSnapshot> _snapshotController =
      StreamController<TranscriptionQueueSnapshot>.broadcast();

  QueueBootstrapState _bootstrapState = const QueueBootstrapNotStarted();
  bool _draining = false;
  bool _asrReady = false;
  String? _processing;

  StreamSubscription<List<NoteEntity>>? _queuedSub;
  StreamSubscription<String>? _noteDeletedSub;
  StreamSubscription<bool>? _asrReadySub;
  TranscriptionQueueSnapshot? _lastSnapshot;

  Stream<TranscriptionQueueSnapshot> get snapshots =>
      _snapshotController.stream;

  TranscriptionQueueSnapshot get current => _lastSnapshot ??= _buildSnapshot();

  bool get _canStartDrain =>
      !_draining && !_breaker.isPaused && _asrReady && _bootstrapState.isReady;

  /// Cold-start recovery + подписка на repo. Не бросает — любая ошибка
  /// становится `bootstrapState.error(failure)`. Автоматически вызывается
  /// injectable'ом через `@PostConstruct()` сразу после DI-конструирования.
  @PostConstruct(preResolve: true)
  Future<void> start() async {
    if (_bootstrapState.isReady || _bootstrapState.isLoading) return;

    try {
      _bootstrapState = const QueueBootstrapLoading();
      _emitSnapshot();

      _asrReady = _asrService.isInitialized;
      _asrReadySub ??= _asrService.stateStream.listen(_onAsrReadyChanged);
      _noteDeletedSub ??= _noteRepository.onDeleted.listen(_onNoteDeleted);

      await _noteRepository.resetTranscribingToQueued();

      // `watchQueued()` (ObjectBox `triggerImmediately: true`) доставит
      // текущий snapshot БД первым же событием как microtask — это и
      // есть наш seed. Отдельный `getQueued()` не нужен: одна атомарная
      // подписка == нет окна «reset прошёл, но подписки ещё нет».
      _queuedSub ??= _noteRepository.watchQueued().listen(
        _onQueuedChanged,
        onError: _onStreamError,
      );

      _bootstrapState = const QueueBootstrapReady();
    } catch (error, stackTrace) {
      developer.log(
        'TranscriptionQueueService.start failed',
        error: error,
        stackTrace: stackTrace,
        name: 'TranscriptionQueue',
      );
      _bootstrapState = QueueBootstrapError(AppFailure.from(error, stackTrace));
    } finally {
      _emitSnapshot();
    }

    if (_bootstrapState.isReady) _scheduleDrain();
  }

  /// Вызывается только в тестах. В проде сервис живёт всю сессию как
  /// `@Singleton`.
  @disposeMethod
  Future<void> dispose() async {
    await _cancelSubscriptions();
    if (!_snapshotController.isClosed) await _snapshotController.close();
  }

  /// User-triggered повтор bootstrap'а после того, как он упал в error.
  /// Сбрасывает подписки, чтобы [start] заново поднял их в известном
  /// состоянии (иначе при частичном сбое некоторые стримы могли остаться
  /// в полу-инициализированном виде).
  Future<void> retryBootstrap() async {
    if (!_bootstrapState.isError) return;

    await _cancelSubscriptions();
    _queue.clear();
    _cancelRequested.clear();
    _deletedInFlight.clear();
    _processing = null;

    _bootstrapState = const QueueBootstrapNotStarted();
    await start();
  }

  Future<void> _cancelSubscriptions() async {
    await _queuedSub?.cancel();
    _queuedSub = null;
    await _noteDeletedSub?.cancel();
    _noteDeletedSub = null;
    await _asrReadySub?.cancel();
    _asrReadySub = null;
  }

  /// Lifecycle resume: пнуть дренаж без тяжёлого recovery. Безопасен на
  /// каждый foreground-event — не трогает БД и не пересоздаёт подписки.
  void resume() {
    if (!_bootstrapState.isReady || _breaker.isPaused) return;
    _scheduleDrain();
  }

  /// User-action: снимает pause и возвращает failed/cancelled заметку в очередь.
  /// Silent no-op, если bootstrap не завершён или заметка не в failed/cancelled.
  Future<void> retry(String noteUid) async {
    if (!_bootstrapState.isReady) return;

    try {
      final note = await _noteRepository.getByUidOrNull(noteUid);
      if (note == null || !(note.isFailed || note.isCancelled)) return;

      _breaker.reset();
      _cancelRequested.remove(noteUid);
      _deletedInFlight.remove(noteUid);

      await _noteRepository.markQueued(noteUid);
      if (_processing != noteUid) _queue.add(noteUid);
      _emitSnapshot();
      _scheduleDrain();
    } catch (error, stackTrace) {
      developer.log(
        'TranscriptionQueueService.retry failed for $noteUid',
        error: error,
        stackTrace: stackTrace,
        name: 'TranscriptionQueue',
      );
    }
  }

  /// Отмена без удаления заметки. Для in-flight uid `_processOne` после
  /// завершения ASR увидит флаг в `_cancelRequested` и вызовет
  /// `markCancelled` сам.
  Future<void> cancel(String noteUid) async {
    if (!_bootstrapState.isReady) return;

    if (_queue.remove(noteUid)) {
      try {
        await _noteRepository.markCancelled(noteUid);
      } catch (error, stackTrace) {
        developer.log(
          'TranscriptionQueueService.cancel failed for $noteUid',
          error: error,
          stackTrace: stackTrace,
          name: 'TranscriptionQueue',
        );
      }
      _emitSnapshot();
      return;
    }

    if (_processing == noteUid) _cancelRequested.add(noteUid);
    _emitSnapshot();
  }

  /// Массовый retry всех заметок в статусе `failed`. `cancelled` НЕ трогает —
  /// отмена — явное решение пользователя, перекрывать его пакетно нельзя.
  /// Для per-note отмены → queued используется [retry].
  Future<void> retryAll() async {
    if (!_bootstrapState.isReady) return;

    try {
      final failed = await _noteRepository.getFailed();
      if (failed.isEmpty) return;

      _breaker.reset();
      for (final note in failed) {
        _cancelRequested.remove(note.uuid);
        _deletedInFlight.remove(note.uuid);
        await _noteRepository.markQueued(note.uuid);
        if (_processing != note.uuid) _queue.add(note.uuid);
      }
      _emitSnapshot();
      _scheduleDrain();
    } catch (error, stackTrace) {
      developer.log(
        'TranscriptionQueueService.retryAll failed',
        error: error,
        stackTrace: stackTrace,
        name: 'TranscriptionQueue',
      );
    }
  }

  /// Массовая отмена всей очереди (queued). `processing` НЕ трогает —
  /// отмена in-flight — отдельное намеренное решение (per-note cancel).
  /// Стиль консистентен с [retryAll]: один `_emitSnapshot` в конце.
  Future<void> cancelAll() async {
    if (!_bootstrapState.isReady || _queue.isEmpty) return;

    for (final uid in _queue) {
      try {
        _queue.remove(uid);
        await _noteRepository.markCancelled(uid);
      } catch (error, stackTrace) {
        developer.log(
          'TranscriptionQueueService.cancelAll failed for $uid',
          error: error,
          stackTrace: stackTrace,
          name: 'TranscriptionQueue',
        );
      }
    }

    _emitSnapshot();
  }

  /// Массовое «убрать с глаз» всех failed → cancelled. Мягкое действие:
  /// данные и аудио сохраняются, пользователь всё ещё может retry'нуть
  /// индивидуальную заметку.
  Future<void> clearFailedAll() async {
    if (!_bootstrapState.isReady) return;

    try {
      final failed = await _noteRepository.getFailed();
      for (final note in failed) {
        await _noteRepository.markCancelled(note.uuid);
      }
    } catch (error, stackTrace) {
      developer.log(
        'TranscriptionQueueService.clearFailedAll failed',
        error: error,
        stackTrace: stackTrace,
        name: 'TranscriptionQueue',
      );
    }
  }

  /// Per-note аналог [clearFailedAll]: failed → cancelled для одной заметки.
  Future<void> dismissFailed(String noteUid) async {
    if (!_bootstrapState.isReady) return;

    try {
      final note = await _noteRepository.getByUidOrNull(noteUid);
      if (note == null || !note.isFailed) return;

      await _noteRepository.markCancelled(noteUid);
    } catch (error, stackTrace) {
      developer.log(
        'TranscriptionQueueService.dismissFailed failed for $noteUid',
        error: error,
        stackTrace: stackTrace,
        name: 'TranscriptionQueue',
      );
    }
  }

  void _onQueuedChanged(List<NoteEntity> queued) {
    // In-flight uid исключаем явно: его нет в `_queue`, но дубль в очередь
    // попадать не должен.
    final processing = _processing;
    final added = _queue.addAll([
      for (final note in queued)
        if (note.uuid != processing) note.uuid,
    ]);

    if (added == 0) return;

    _emitSnapshot();
    _scheduleDrain();
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    developer.log(
      'watchQueued stream error',
      error: error,
      stackTrace: stackTrace,
      name: 'TranscriptionQueue',
    );
  }

  void _scheduleDrain() => unawaited(_drain());

  Future<void> _drain() async {
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

      if (await _consumeAbort(noteUid)) return;

      final audio = note.audio;
      if (audio == null) {
        await _failWithReason(
          noteUid,
          TranscriptionFailureReason.audioFileMissing,
        );
        return;
      }

      // Pre-empt перед стартом ASR: между top-of-loop `_asrReady` и этой
      // точкой были await'ы (getByUidOrNull, _consumeAbort, audio-check),
      // модель могла пропасть.
      if (!_asrService.isInitialized) {
        _asrReady = false;
        _queue.addFirst(noteUid);
        return;
      }

      final modelName = _asrService.currentModel?.name ?? '';
      await _noteRepository.markTranscribing(noteUid);

      // TODO(perf): прервать in-flight ASR при cancel/delete, не дожидаясь
      //   завершения транскрибации.
      final result = await _transcribeWithTimeout(audio);

      // Пользователь мог удалить или отменить заметку за время await —
      // отбрасываем результат. Для cancelled — явно ставим статус.
      if (await _consumeAbort(noteUid)) return;

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

  /// Возвращает true, если для `noteUid` был зафиксирован abort (user
  /// cancel ИЛИ delete) — вызывающий должен прекратить обработку.
  Future<bool> _consumeAbort(String noteUid) async {
    final cancelled = _cancelRequested.remove(noteUid);
    final deleted = _deletedInFlight.remove(noteUid);

    if (!cancelled && !deleted) return false;

    // Deleted: заметки уже нет в БД, `markCancelled` был бы no-op.
    // Cancelled: персистим статус.
    if (cancelled && !deleted) {
      try {
        await _noteRepository.markCancelled(noteUid);
      } catch (error, stackTrace) {
        developer.log(
          'markCancelled failed for $noteUid',
          error: error,
          stackTrace: stackTrace,
          name: 'TranscriptionQueue',
        );
      }
    }

    return true;
  }

  Future<AsrResult> _transcribeWithTimeout(NoteAudioEntity audio) async {
    final absolutePath = await _resolveAudioAbsolutePath(audio);

    return _asrService
        .transcribeFile(absolutePath)
        .timeout(
          _transcribeTimeout,
          onTimeout: () => throw const TranscribeTimeoutException(),
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

    final reason = classifyTranscriptionFailure(error);
    await _noteRepository.failTranscription(uid: noteUid, reason: reason);
    _breaker.recordFailure();
  }

  Future<void> _onAsrReadyChanged(bool ready) async {
    if (_asrReady == ready) return;

    _asrReady = ready;
    _emitSnapshot();

    if (!ready) return;

    // Модель стала доступна, а bootstrap в error — шанс поднять сервис
    // заново без участия пользователя. Если retryBootstrap снова
    // упадёт — состояние опять `error`, UI-кнопка остаётся.
    if (_bootstrapState.isError) {
      await retryBootstrap();
      return;
    }

    // Безусловный reset: появление модели == fresh start для очереди.
    // Если decode-failures пойдут снова и накопятся 3 подряд — breaker
    // снова встанет, это OK.
    _breaker.reset();
    _scheduleDrain();
    _emitSnapshot();
  }

  void _onNoteDeleted(String noteUid) {
    // Если заметку удалили, пока она висит в `_queue` — просто убираем.
    // Если она in-flight — запоминаем, `_processOne` после ASR отбросит
    // результат.
    if (!_queue.remove(noteUid) && _processing == noteUid) {
      _deletedInFlight.add(noteUid);
      _cancelRequested.remove(noteUid);
    }

    _emitSnapshot();
  }

  Future<String> _resolveAudioAbsolutePath(NoteAudioEntity audio) {
    return AudioPaths.resolveRelativePath(audio.relativePath);
  }

  TranscriptionQueueSnapshot _buildSnapshot() => TranscriptionQueueSnapshot(
    bootstrapState: _bootstrapState,
    queued: List.unmodifiable(_queue),
    processing: _processing,
    cancelRequested: Set.unmodifiable(_cancelRequested),
    runtimeReason: _computeRuntimeReason(),
  );

  /// Причина простоя дренажа. Breaker приоритетнее, т.к. он — следствие
  /// реальных провалов и требует явного сигнала пользователю.
  QueueRuntimeReason _computeRuntimeReason() {
    if (_breaker.isPaused) return QueueRuntimeReason.breakerTripped;
    if (_bootstrapState.isReady && !_asrReady) {
      return QueueRuntimeReason.awaitingModel;
    }

    return QueueRuntimeReason.none;
  }

  void _emitSnapshot() {
    if (_snapshotController.isClosed) return;

    final nextSnapshot = _buildSnapshot();
    if (_lastSnapshot == nextSnapshot) return;

    _lastSnapshot = nextSnapshot;
    _snapshotController.add(nextSnapshot);
  }
}
