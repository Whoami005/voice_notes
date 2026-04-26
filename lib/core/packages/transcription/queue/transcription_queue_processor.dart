import 'dart:async';
import 'dart:developer' as developer;

import 'package:voice_notes/core/extensions/string_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/transcription/queue/queued_transcription_task.dart';
import 'package:voice_notes/core/packages/transcription/queue/transcription_queue_runtime.dart';
import 'package:voice_notes/core/packages/transcription/queue/transcription_task_planner.dart';
import 'package:voice_notes/core/packages/transcription/transcription_failure_classifier.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/data/local/preferences/transcription_queue_preferences.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

final class TranscriptionQueueProcessor {
  final NoteRepository _noteRepository;
  final AsrService _asrService;
  final RecordingPreferences _preferences;
  final TranscriptionQueuePreferences _queuePreferences;
  final TranscriptionQueueRuntime _runtime;
  final TranscriptionTaskPlanner _taskPlanner;
  final Duration _transcribeTimeout;
  final void Function() _emitSnapshot;

  const TranscriptionQueueProcessor({
    required NoteRepository noteRepository,
    required AsrService asrService,
    required RecordingPreferences preferences,
    required TranscriptionQueuePreferences queuePreferences,
    required TranscriptionQueueRuntime runtime,
    required TranscriptionTaskPlanner taskPlanner,
    required Duration transcribeTimeout,
    required void Function() emitSnapshot,
  }) : _noteRepository = noteRepository,
       _asrService = asrService,
       _preferences = preferences,
       _queuePreferences = queuePreferences,
       _runtime = runtime,
       _taskPlanner = taskPlanner,
       _transcribeTimeout = transcribeTimeout,
       _emitSnapshot = emitSnapshot;

  Future<void> processOne(String noteUid) async {
    bool guardStateArmed = false;

    try {
      final task = await _prepareTask(noteUid);
      if (task == null) return;

      await _markProcessingStarted(task);
      guardStateArmed = true;
      final result = await _transcribeWithTimeout(task);

      // Пользователь мог удалить или отменить заметку за время await —
      // отбрасываем результат. Для cancelled — явно ставим статус.
      if (await _consumeAbort(noteUid)) return;

      await _completeTask(task, result);
    } on AsrModelChangedException {
      _runtime.queue.addFirst(noteUid);
    } on AsrCancelledException {
      await _handleCancelledTask(noteUid);
    } catch (error, stackTrace) {
      await _handleProcessingFailure(noteUid, error, stackTrace);
    } finally {
      if (guardStateArmed) await _clearGuardStateSafely(noteUid);
      _runtime.clearProcessingRuntime(noteUid);
    }
  }

  Future<QueuedTranscriptionTask?> _prepareTask(String noteUid) async {
    final note = await _noteRepository.getByUidOrNull(noteUid);
    if (note == null) return null;

    if (await _consumeAbort(noteUid)) return null;

    final audio = note.audio;
    if (audio == null) {
      await _failWithReason(
        noteUid,
        TranscriptionFailureReason.audioFileMissing,
      );
      return null;
    }

    final model = _resolveReadyModel(noteUid);
    if (model == null) return null;

    final transcriptionPlan = await _taskPlanner.buildPlan(
      model: model,
      audio: audio,
    );

    return QueuedTranscriptionTask(
      noteUid: noteUid,
      audio: audio,
      model: model,
      transcriptionPlan: transcriptionPlan,
      cancelToken: AsrCancelToken(),
    );
  }

  AsrModelEntity? _resolveReadyModel(String noteUid) {
    // Pre-empt перед стартом ASR: между top-of-loop `asrReady` и этой
    // точкой были await'ы (getByUidOrNull, _consumeAbort, audio-check),
    // модель могла пропасть.
    if (!_asrService.isInitialized) {
      _runtime.asrReady = false;
      _runtime.queue.addFirst(noteUid);
      return null;
    }

    final model = _asrService.currentModel;
    if (model == null) {
      _runtime.asrReady = false;
      _runtime.queue.addFirst(noteUid);
      return null;
    }

    return model;
  }

  Future<void> _markProcessingStarted(QueuedTranscriptionTask task) async {
    _runtime.processingSupportsInteractiveProgress =
        task.transcriptionPlan.supportsInteractiveProgress;
    _runtime.processingSupportsCancellation =
        task.transcriptionPlan.supportsCancellation;
    _runtime.currentCancelToken = task.cancelToken;

    await _noteRepository.markTranscribing(task.noteUid);
    await _queuePreferences.markRunningTranscription();
    _emitSnapshot();
  }

  Future<void> _completeTask(
    QueuedTranscriptionTask task,
    AsrResult result,
  ) async {
    await _noteRepository.completeTranscription(
      uid: task.noteUid,
      text: result.text,
      language: result.detectedLanguage ?? '',
      modelName: task.model.name,
      wordCount: result.text.wordCount,
      deleteAudio: !_preferences.keepOriginals,
    );
    _runtime.breaker.recordSuccess();
  }

  Future<void> _handleCancelledTask(String noteUid) async {
    // Instant-cancel от interactive worker-пайплайна. Seed'нуть markCancelled
    // (если заметка ещё существует) и не трогать breaker — cancel
    // нейтрален, не success и не failure.
    try {
      _runtime.cancelRequested.remove(noteUid);
      await _noteRepository.markCancelled(noteUid);
    } catch (error, stackTrace) {
      developer.log(
        'markCancelled failed for $noteUid after AsrCancelledException',
        error: error,
        stackTrace: stackTrace,
        name: 'TranscriptionQueue',
      );
    }
  }

  /// Возвращает true, если для `noteUid` был зафиксирован abort (user
  /// cancel ИЛИ delete) — вызывающий должен прекратить обработку.
  Future<bool> _consumeAbort(String noteUid) async {
    final cancelled = _runtime.cancelRequested.remove(noteUid);
    final deleted = _runtime.deletedInFlight.remove(noteUid);

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

  Future<AsrResult> _transcribeWithTimeout(QueuedTranscriptionTask task) async {
    final absolutePath = await _resolveAudioAbsolutePath(task.audio);

    return _asrService
        .transcribeFile(
          absolutePath,
          onProgress: (progress) => _onProgress(progress, task.noteUid),
          cancelToken: task.cancelToken,
          strategyOverride: task.transcriptionPlan.strategy,
          audioDurationHint: task.audio.duration,
          transcriptionPlan: task.transcriptionPlan,
          expectedModel: task.model,
        )
        .timeout(
          _transcribeTimeout,
          onTimeout: () => throw const TranscribeTimeoutException(),
        );
  }

  /// Gate'д приём progress-событий от воркера. Дропаем, если:
  /// - событие для не той заметки, что сейчас `processing` (stale);
  /// - пользователь уже отменил задачу (`cancelRequested`);
  /// - заметка удалена в процессе (`deletedInFlight`).
  void _onProgress(AsrTranscribeProgress progress, String forNoteUid) {
    if (forNoteUid != _runtime.processing ||
        _runtime.cancelRequested.contains(forNoteUid) ||
        _runtime.deletedInFlight.contains(forNoteUid)) {
      return;
    }

    _runtime.lastProgress = progress;
    _runtime.lastProgressNoteUid = forNoteUid;
    _emitSnapshot();
  }

  Future<void> _failWithReason(
    String noteUid,
    TranscriptionFailureReason reason,
  ) async {
    await _noteRepository.failTranscription(uid: noteUid, reason: reason);
    _runtime.breaker.recordFailure();
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
    _runtime.breaker.recordFailure();
  }

  Future<void> _clearGuardStateSafely(String noteUid) async {
    try {
      await _queuePreferences.clearGuardState();
    } catch (error, stackTrace) {
      developer.log(
        'clearGuardState failed for $noteUid',
        error: error,
        stackTrace: stackTrace,
        name: 'TranscriptionQueue',
      );
    }
  }

  Future<String> _resolveAudioAbsolutePath(NoteAudioEntity audio) {
    return AudioPaths.resolveRelativePath(audio.relativePath);
  }
}
