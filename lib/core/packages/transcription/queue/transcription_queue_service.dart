import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/transcription/queue/priority_transcription_task.dart';
import 'package:voice_notes/core/packages/transcription/queue/transcription_queue_processor.dart';
import 'package:voice_notes/core/packages/transcription/queue/transcription_queue_runtime.dart';
import 'package:voice_notes/core/packages/transcription/queue/transcription_task_planner.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/data/local/preferences/transcription_queue_preferences.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

/// FIFO-диспетчер очереди транскрибации и единственный владелец queue domain.
///
/// Source of truth по статусам — БД. Сервис подписан на
/// `NoteRepository.watchQueued`, сам подхватывает новые заметки и
/// выполняет их через ASR. Продюсеры (например, `RecordingCubit`) пишут
/// заметку в БД со статусом `queued` — сервис увидит это через stream
/// и не требует явного `enqueue`.
///
/// Gate drain'а — runtime `asrReady`: пока модель не готова, заметки копятся
/// в runtime FIFO, но не фейлятся с `noModelSelected`. Bootstrap — через
/// `@PostConstruct()` injectable: сервис self-bootstrap'ится при первом
/// разрешении DI, AppInitializer не участвует.
///
/// `start()` **не бросает**: любой сбой переводит `bootstrapState` в
/// `error(failure)`; UI может вызвать `retryBootstrap()`.
@Singleton(as: TranscriptionQueueController)
class TranscriptionQueueService implements TranscriptionQueueController {
  TranscriptionQueueService({
    required NoteRepository noteRepository,
    required AsrService asrService,
    required RecordingPreferences preferences,
    required TranscriptionQueuePreferences queuePreferences,
  }) : _noteRepository = noteRepository,
       _asrService = asrService,
       _preferences = preferences,
       _queuePreferences = queuePreferences,
       _transcribeTimeout = const Duration(minutes: 30) {
    _processor = _buildProcessor();
  }

  /// Тест-only конструктор. Даёт возможность подставить короткий таймаут
  /// в unit-тестах без регистрации отдельной `Duration` в DI.
  @visibleForTesting
  TranscriptionQueueService.forTesting({
    required NoteRepository noteRepository,
    required AsrService asrService,
    required RecordingPreferences preferences,
    required TranscriptionQueuePreferences queuePreferences,
    required Duration transcribeTimeout,
  }) : _noteRepository = noteRepository,
       _asrService = asrService,
       _preferences = preferences,
       _queuePreferences = queuePreferences,
       _transcribeTimeout = transcribeTimeout {
    _processor = _buildProcessor();
  }

  final NoteRepository _noteRepository;
  final AsrService _asrService;
  final RecordingPreferences _preferences;
  final TranscriptionQueuePreferences _queuePreferences;

  /// Максимальное время на одну транскрибацию. Защищает от зависания
  /// sherpa-onnx FFI внутри изолята — таймаут переводит заметку в failed
  /// с `transcriptionTimedOut`, очередь продолжает работать.
  final Duration _transcribeTimeout;

  final TranscriptionQueueRuntime _runtime = TranscriptionQueueRuntime();
  final TranscriptionTaskPlanner _taskPlanner = TranscriptionTaskPlanner();
  final Queue<PriorityTranscriptionTask> _priorityQueue =
      Queue<PriorityTranscriptionTask>();
  final StreamController<TranscriptionQueueSnapshot> _snapshotController =
      StreamController<TranscriptionQueueSnapshot>.broadcast();
  late final TranscriptionQueueProcessor _processor;

  StreamSubscription<List<NoteEntity>>? _queuedSub;
  StreamSubscription<String>? _noteDeletedSub;
  StreamSubscription<bool>? _asrReadySub;

  @override
  Stream<TranscriptionQueueSnapshot> get snapshots =>
      _snapshotController.stream;

  @override
  TranscriptionQueueSnapshot get current => _runtime.current;

  bool get _canStartDrain =>
      !_runtime.draining && (_canProcessPriorityWork || _canProcessQueuedWork);

  bool get _canProcessPriorityWork =>
      _priorityQueue.isNotEmpty && _hasReadyModel;

  bool get _canProcessQueuedWork => _runtime.canProcessQueuedWork;

  bool get _hasReadyModel =>
      _asrService.isInitialized && _asrService.currentModel != null;

  TranscriptionQueueProcessor _buildProcessor() => TranscriptionQueueProcessor(
    noteRepository: _noteRepository,
    asrService: _asrService,
    preferences: _preferences,
    queuePreferences: _queuePreferences,
    runtime: _runtime,
    taskPlanner: _taskPlanner,
    transcribeTimeout: _transcribeTimeout,
    emitSnapshot: _emitSnapshot,
  );

  @override
  Future<AsrResult> transcribePriorityFile(
    String filePath, {
    required Duration audioDurationHint,
    void Function()? onStarted,
  }) async {
    _ensurePriorityModelReady();

    final task = PriorityTranscriptionTask(
      filePath: filePath,
      audioDurationHint: audioDurationHint,
      onStarted: onStarted,
      completer: Completer<AsrResult>.sync(),
    );

    _priorityQueue.add(task);
    _scheduleDrain();

    return task.future;
  }

  /// Cold-start recovery + подписка на repo. Не бросает — любая ошибка
  /// становится `bootstrapState.error(failure)`. Автоматически вызывается
  /// injectable'ом через `@PostConstruct()` сразу после DI-конструирования.
  @PostConstruct(preResolve: true)
  Future<void> start() async {
    if (_runtime.bootstrapState.isReady || _runtime.bootstrapState.isLoading) {
      return;
    }

    try {
      await _runBootstrap();
      _runtime.bootstrapState = const QueueBootstrapReady();
    } catch (error, stackTrace) {
      developer.log(
        'TranscriptionQueueService.start failed',
        error: error,
        stackTrace: stackTrace,
        name: 'TranscriptionQueue',
      );
      _runtime.bootstrapState = QueueBootstrapError(
        AppFailure.from(error, stackTrace),
      );
    } finally {
      _emitSnapshot();
    }

    if (_runtime.bootstrapState.isReady) _scheduleDrain();
  }

  Future<void> _runBootstrap() async {
    _runtime.bootstrapState = const QueueBootstrapLoading();
    _emitSnapshot();

    _bindRuntimeStreams();
    await _recoverColdStartState();
    _bindQueuedStream();
  }

  void _bindRuntimeStreams() {
    _runtime.asrReady = _asrService.isInitialized;
    _asrReadySub ??= _asrService.stateStream.listen(_onAsrReadyChanged);
    _noteDeletedSub ??= _noteRepository.onDeleted.listen(_onNoteDeleted);
  }

  Future<void> _recoverColdStartState() async {
    await _noteRepository.resetTranscribingToQueued();
    _runtime.pausedAfterInterruptedRun = await _restoreInterruptedRunGuard();
  }

  void _bindQueuedStream() {
    // `watchQueued()` (ObjectBox `triggerImmediately: true`) доставит
    // текущий snapshot БД первым же событием как microtask — это и
    // есть наш seed. Отдельный `getQueued()` не нужен: одна атомарная
    // подписка == нет окна «reset прошёл, но подписки ещё нет».
    _queuedSub ??= _noteRepository.watchQueued().listen(
      _onQueuedChanged,
      onError: _onStreamError,
    );
  }

  /// Вызывается только в тестах. В проде сервис живёт всю сессию как
  /// `@Singleton`.
  @disposeMethod
  @override
  Future<void> dispose() async {
    await _cancelSubscriptions();
    if (!_snapshotController.isClosed) await _snapshotController.close();
  }

  /// User-triggered повтор bootstrap'а после того, как он упал в error.
  /// Сбрасывает подписки, чтобы [start] заново поднял их в известном
  /// состоянии (иначе при частичном сбое некоторые стримы могли остаться
  /// в полу-инициализированном виде).
  @override
  Future<void> retryBootstrap() async {
    if (!_runtime.bootstrapState.isError) return;

    await _cancelSubscriptions();
    _runtime
      ..resetTransientState()
      ..bootstrapState = const QueueBootstrapNotStarted();
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
  @override
  void resume() {
    if (!_runtime.bootstrapState.isReady || _runtime.breaker.isPaused) return;
    _scheduleDrain();
  }

  @override
  Future<void> resumeAfterInterruptedRun() async {
    if (!_runtime.bootstrapState.isReady ||
        !_runtime.pausedAfterInterruptedRun) {
      return;
    }

    await _queuePreferences.clearGuardState();
    _runtime.pausedAfterInterruptedRun = false;
    _emitSnapshot();
    _scheduleDrain();
  }

  /// User-action: снимает pause и возвращает failed/cancelled заметку в очередь.
  /// Silent no-op, если bootstrap не завершён или заметка не в failed/cancelled.
  @override
  Future<void> retry(String noteUid) async {
    if (!_runtime.bootstrapState.isReady) return;

    try {
      final note = await _noteRepository.getByUidOrNull(noteUid);
      if (note == null || !(note.isFailed || note.isCancelled)) return;

      _runtime.breaker.reset();
      _runtime.cancelRequested.remove(noteUid);
      _runtime.deletedInFlight.remove(noteUid);

      await _noteRepository.markQueued(noteUid);
      if (_runtime.processing != noteUid) _runtime.queue.add(noteUid);
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

  /// Отмена без удаления заметки. Для in-flight uid processor после
  /// завершения ASR увидит флаг в `cancelRequested` и вызовет
  /// `markCancelled` сам.
  @override
  Future<void> cancel(String noteUid) async {
    if (!_runtime.bootstrapState.isReady) return;

    if (_runtime.queue.remove(noteUid)) {
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

    if (_runtime.processing == noteUid) {
      _runtime.cancelRequested.add(noteUid);
      // Interactive-стратегии прерываются между чанками через токен.
      // Для blocking singlePass fallback остаётся прежним:
      // post-decode consume-abort в _processOne.
      _runtime.currentCancelToken?.cancel();
    }
    _emitSnapshot();
  }

  /// Массовый retry всех заметок в статусе `failed`. `cancelled` НЕ трогает —
  /// отмена — явное решение пользователя, перекрывать его пакетно нельзя.
  /// Для per-note отмены → queued используется [retry].
  @override
  Future<void> retryAll() async {
    if (!_runtime.bootstrapState.isReady) return;

    try {
      final failed = await _noteRepository.getFailed();
      if (failed.isEmpty) return;

      _runtime.breaker.reset();
      for (final note in failed) {
        _runtime.cancelRequested.remove(note.uuid);
        _runtime.deletedInFlight.remove(note.uuid);
        await _noteRepository.markQueued(note.uuid);
        if (_runtime.processing != note.uuid) _runtime.queue.add(note.uuid);
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
  @override
  Future<void> cancelAll() async {
    if (!_runtime.bootstrapState.isReady || _runtime.queue.isEmpty) return;

    final queuedSnapshot = [..._runtime.queue];

    for (final uid in queuedSnapshot) {
      try {
        await _noteRepository.markCancelled(uid);
        _runtime.queue.remove(uid);
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
  @override
  Future<void> clearFailedAll() async {
    if (!_runtime.bootstrapState.isReady) return;

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
  @override
  Future<void> dismissFailed(String noteUid) async {
    if (!_runtime.bootstrapState.isReady) return;

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
    // In-flight uid исключаем явно: его нет в runtime queue, но дубль в очередь
    // попадать не должен.
    final processing = _runtime.processing;
    final added = _runtime.queue.addAll([
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

    _runtime.draining = true;
    try {
      while (_priorityQueue.isNotEmpty || _runtime.queue.isNotEmpty) {
        if (_priorityQueue.isNotEmpty) {
          final task = _priorityQueue.removeFirst();
          await _processPriority(task);
          continue;
        }

        if (!_canProcessQueuedWork) break;

        final noteUid = _runtime.queue.removeFirst();
        _runtime.processing = noteUid;
        _emitSnapshot();

        await _processor.processOne(noteUid);

        _runtime.processing = null;
        _emitSnapshot();
      }

      if (_runtime.breaker.isPaused) {
        developer.log(
          'TranscriptionQueue paused after consecutive failures',
          name: 'TranscriptionQueue',
        );
      }
    } finally {
      _runtime.draining = false;
      _emitSnapshot();
      if (_canStartDrain) _scheduleDrain();
    }
  }

  Future<void> _processPriority(PriorityTranscriptionTask task) async {
    try {
      _ensurePriorityModelReady();
      task.markStarted();

      final result = await _asrService.transcribeFile(
        task.filePath,
        audioDurationHint: task.audioDurationHint,
      );
      task.complete(result);
    } catch (error, stackTrace) {
      task.completeError(error, stackTrace);
    }
  }

  void _ensurePriorityModelReady() {
    if (_hasReadyModel) return;

    if (_runtime.asrReady) {
      _runtime.asrReady = false;
      _emitSnapshot();
    }

    throw const AsrNotInitializedException();
  }

  Future<void> _onAsrReadyChanged(bool ready) async {
    if (_runtime.asrReady == ready) return;

    _runtime.asrReady = ready;
    _emitSnapshot();

    if (!ready) return;

    // Модель стала доступна, а bootstrap в error — шанс поднять сервис
    // заново без участия пользователя. Если retryBootstrap снова
    // упадёт — состояние опять `error`, UI-кнопка остаётся.
    if (_runtime.bootstrapState.isError) {
      await retryBootstrap();
      return;
    }

    // Безусловный reset: появление модели == fresh start для очереди.
    // Если decode-failures пойдут снова и накопятся 3 подряд — breaker
    // снова встанет, это OK.
    _runtime.breaker.reset();
    _scheduleDrain();
    _emitSnapshot();
  }

  void _onNoteDeleted(String noteUid) {
    // Если заметку удалили, пока она висит в runtime queue — просто убираем.
    // Если она in-flight — запоминаем, processor после ASR отбросит
    // результат. Streaming-decode прерываем мгновенно через cancelToken,
    // чтобы не жечь CPU после delete.
    if (!_runtime.queue.remove(noteUid) && _runtime.processing == noteUid) {
      _runtime.deletedInFlight.add(noteUid);
      _runtime.cancelRequested.remove(noteUid);
      _runtime.currentCancelToken?.cancel();
    }

    _emitSnapshot();
  }

  void _emitSnapshot() {
    if (_snapshotController.isClosed) return;

    final nextSnapshot = _runtime.buildSnapshot();
    if (_runtime.lastSnapshot == nextSnapshot) return;

    _runtime.lastSnapshot = nextSnapshot;
    _snapshotController.add(nextSnapshot);
  }

  Future<bool> _restoreInterruptedRunGuard() async {
    final guardState = await _queuePreferences.getGuardState();
    switch (guardState) {
      case TranscriptionQueueGuardState.runningTranscription:
        await _queuePreferences.markPausedAfterInterruption();
        return true;
      case TranscriptionQueueGuardState.pausedAfterInterruption:
        return true;
      case null:
        return false;
    }
  }
}
