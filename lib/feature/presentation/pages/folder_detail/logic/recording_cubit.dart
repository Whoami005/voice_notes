import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/extensions/string_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_exception.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/note_ingestion/note_ingestion_exception.dart';
import 'package:voice_notes/core/packages/note_ingestion/note_ingestion_service.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/packages/uuid/uuid_manager.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/feature/domain/enums/recording_state.dart'
    show RecordingInputState;
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'recording_state.dart';

/// Cubit жизненного цикла записи.
///
/// Два режима:
/// - **folder-mode** (`folderId != null`, messenger-UX): запись → моментально
///   Idle, queued-заметка создаётся в фоне через [NoteIngestionService],
///   транскрибация идёт в очереди асинхронно. Прогресс показывается per-note
///   в `note_bubble`, не в баре записи.
/// - **Quick Record** (`folderId == null`): запись → синхронная транскрибация
///   через priority-lane [TranscriptionQueueController] → clipboard. Заметка
///   не создаётся.
///
/// ## Каналы ошибок
///
/// - Recorder (permission, already recording, stop crash) →
///   [RecordingErrorState] + 2s idle-reset (foreground state).
/// - Quick Record ASR (`_processQuickRecord`) → [RecordingErrorState] +
///   ErrorDialog через `VoiceRecordButton._handleStateChange`.
/// - Ingestion (pre-queue: `createQueued`, файл пропал между recorder и
///   service) → [RecordingErrorState] **с guard’ом** на `RecordingIdleState`:
///   не перекрываем активную новую запись; рендерится через существующий
///   toast в `FolderDetailRecordingBar._showErrorToast`.
/// - Транскрибация (ASR fail, timeout) → обрабатывается внутри
///   `TranscriptionQueueService` → `failTranscription` → inline-статус в
///   `note_bubble._StatusContent` с retry-кнопкой. **Никакого toast/effect**:
///   заметка уже в списке.
class RecordingCubit extends BaseCubit<RecordingState> {
  final AudioRecordingService _recordingService;
  final TranscriptionQueueController _queueController;
  final NoteRepository _noteRepository;
  final AudioPlaybackController _playbackController;
  final NoteIngestionService _ingestionService;

  StreamSubscription<double>? _amplitudeSubscription;
  Timer? _idleResetTimer;

  /// Скользящее окно последних N амплитуд для live-waveform.
  /// При 100ms-интервале 64 сэмпла ≈ 6.4 секунды истории.
  static const int _amplitudeBufferSize = 64;
  final List<double> _amplitudeBuffer = [];

  /// `null` = Quick Record в буфер обмена.
  final String? folderId;

  /// Uuid будущей заметки, сгенерированный в момент startRecording.
  /// Используется как имя файла и как uid создаваемой заметки, чтобы
  /// запись и её метаданные были связаны стабильным идентификатором.
  String? _pendingNoteUuid;

  RecordingCubit({
    required AudioRecordingService recordingService,
    required TranscriptionQueueController queueController,
    required NoteRepository noteRepository,
    required AudioPlaybackController playbackController,
    required NoteIngestionService ingestionService,
    this.folderId,
  }) : _recordingService = recordingService,
       _queueController = queueController,
       _noteRepository = noteRepository,
       _playbackController = playbackController,
       _ingestionService = ingestionService,
       super(const RecordingIdleState());

  Future<void> startRecording() async {
    if (state is! RecordingIdleState) return;

    try {
      await _playbackController.pause();

      // Генерируем uuid заранее: им будет именоваться файл на диске,
      // и та же строка станет uid заметки после транскрибации.
      _pendingNoteUuid = UuidManager.v1();

      await _recordingService.startRecording(
        noteUuid: _pendingNoteUuid!,
        onMaxDurationReached: stopRecording,
      );

      // Отменяем возможный delayed-reset от предыдущего success/error,
      // чтобы он не переключил Active → Idle посреди новой записи.
      _idleResetTimer?.cancel();
      _amplitudeBuffer.clear();
      emit(const RecordingActiveState());

      _amplitudeSubscription = _recordingService.amplitudeStream.listen((amp) {
        if (state is! RecordingActiveState) return;

        _amplitudeBuffer.add(amp);
        if (_amplitudeBuffer.length > _amplitudeBufferSize) {
          _amplitudeBuffer.removeAt(0);
        }

        final current = state as RecordingActiveState;
        emit(
          current.copyWith(
            duration: _recordingService.currentDuration,
            amplitudes: List.unmodifiable(_amplitudeBuffer),
          ),
        );
      }, onError: addError);
    } on MicrophonePermissionDeniedException {
      _pendingNoteUuid = null;
      emit(const RecordingErrorState(RecordingFailure.permissionDenied()));
      _resetToIdleDelayed();
    } on RecordingAlreadyActiveException {
      _pendingNoteUuid = null;
      emit(const RecordingErrorState(RecordingFailure.alreadyRecording()));
    } catch (e, s) {
      _pendingNoteUuid = null;
      safeEmit(RecordingErrorState(logError(e, s)));
      _resetToIdleDelayed();
    }
  }

  /// Остановить запись.
  ///
  /// Folder-mode: моментально возвращаемся в Idle; createQueued + постановка
  ///   в очередь — в фоне через [NoteIngestionService]. Пользователь может
  ///   сразу записать следующую заметку.
  /// Quick Record: переходим в [RecordingTranscribingState] и синхронно
  ///   транскрибируем результат в clipboard.
  Future<void> stopRecording() async {
    if (state is! RecordingActiveState) return;

    final noteUuid = _pendingNoteUuid;
    if (noteUuid == null) return;

    try {
      await _amplitudeSubscription?.cancel();
      _amplitudeBuffer.clear();

      final result = await _recordingService.stopRecording();

      // Если cubit закрылся во время остановки записи — выходим
      if (isClosed) return;

      final currentFolderId = folderId;
      if (currentFolderId != null) {
        _pendingNoteUuid = null;
        _idleResetTimer?.cancel();
        emit(const RecordingIdleState());

        unawaited(
          _ingestInBackground(
            noteUuid: noteUuid,
            duration: result.duration,
            folderId: currentFolderId,
          ),
        );
        return;
      }

      unawaited(
        _processQuickRecord(
          filePath: result.filePath,
          duration: result.duration,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;

      _pendingNoteUuid = null;
      safeEmit(RecordingErrorState(logError(e, s)));
      _resetToIdleDelayed();
    }
  }

  /// Отбрасывает текущую запись; файл удаляется сервисом.
  Future<void> cancelRecording() async {
    if (state is! RecordingActiveState) return;

    try {
      await _amplitudeSubscription?.cancel();
      _amplitudeBuffer.clear();
      await _recordingService.cancelRecording();

      _pendingNoteUuid = null;
      emit(const RecordingIdleState());
    } catch (e, s) {
      _pendingNoteUuid = null;
      addError(e, s);
      emit(const RecordingIdleState());
    }
  }

  void reset() {
    emit(const RecordingIdleState());
  }

  /// Текстовый ввод вместо голосовой записи. Эмитит success/error.
  Future<void> createTextNote(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || state is! RecordingIdleState) return;
    if (folderId == null) return;

    try {
      await _noteRepository.createManualNote(
        text: trimmedText,
        folderUid: folderId,
      );

      emit(
        RecordingSuccessState(
          text: trimmedText,
          duration: Duration.zero,
          wordCount: trimmedText.wordCount,
        ),
      );

      _resetToIdleDelayed();
    } catch (e, s) {
      safeEmit(RecordingErrorState(logError(e, s)));
      _resetToIdleDelayed();
    }
  }

  /// Folder-путь: создание queued-заметки в фоне после возврата UI в Idle.
  ///
  /// Ошибки ingestion’а эмитятся обратно как [RecordingErrorState] **только
  /// если** cubit всё ещё в Idle. Если за миллисекунды ингеста пользователь
  /// успел стартовать новую запись — ошибку глотаем, чтобы не затоптать
  /// живой [RecordingActiveState]. Лог у источника (`NoteIngestionService`)
  /// всё равно есть.
  Future<void> _ingestInBackground({
    required String noteUuid,
    required Duration duration,
    required String folderId,
  }) async {
    try {
      await _ingestionService.ingest(
        uuid: noteUuid,
        folderUid: folderId,
        duration: duration,
      );
    } on NoteIngestionFailed catch (e) {
      if (isClosed) return;
      if (state is! RecordingIdleState) return;

      emit(RecordingErrorState(e.failure));
      _resetToIdleDelayed();
    } catch (e, s) {
      if (isClosed) return;
      if (state is! RecordingIdleState) return;

      safeEmit(RecordingErrorState(logError(e, s)));
      _resetToIdleDelayed();
    }
  }

  /// Quick Record: синхронная транскрибация и копирование в буфер обмена.
  /// Заметка не создаётся. Запрос идёт через priority-lane очереди, чтобы
  /// ASR worker оставался последовательным и Quick Record был следующим после
  /// уже активной транскрибации.
  Future<void> _processQuickRecord({
    required String filePath,
    required Duration duration,
  }) async {
    try {
      final isWaitingForCurrentTranscription =
          _queueController.current.processing != null;

      safeEmit(
        isWaitingForCurrentTranscription
            ? RecordingWaitingTranscriptionSlotState(
                filePath: filePath,
                duration: duration,
              )
            : RecordingTranscribingState(
                filePath: filePath,
                duration: duration,
              ),
      );

      final asrResult = await _queueController.transcribePriorityFile(
        filePath,
        audioDurationHint: duration,
        onStarted: () =>
            _emitQuickRecordStarted(filePath: filePath, duration: duration),
      );

      await _copyToClipboard(asrResult.text);
      _deleteAudioFile(filePath);

      _pendingNoteUuid = null;
      safeEmit(
        RecordingSuccessState(
          text: asrResult.text,
          duration: duration,
          language: asrResult.detectedLanguage,
          wordCount: asrResult.text.wordCount,
        ),
      );
      _resetToIdleDelayed();
    } on AsrNotInitializedException catch (e, s) {
      addError(e, s);
      _failQuickRecord(
        filePath: filePath,
        failure: const RecordingFailure.noModelSelected(),
      );
    } on AsrException catch (e, s) {
      addError(e, s);
      _failQuickRecord(
        filePath: filePath,
        failure: const RecordingFailure.transcriptionFailed(),
      );
    } catch (e, s) {
      _failQuickRecord(filePath: filePath, failure: logError(e, s));
    }
  }

  void _emitQuickRecordStarted({
    required String filePath,
    required Duration duration,
  }) {
    if (isClosed) return;

    final current = state;
    if (current is! RecordingWaitingTranscriptionSlotState) return;
    if (current.filePath != filePath) return;

    safeEmit(
      RecordingTranscribingState(filePath: filePath, duration: duration),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Удаляет аудиофайл Quick Record записи. Happy path — файл уже в clipboard,
  /// хранить его не нужно.
  void _deleteAudioFile(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) unawaited(file.delete());
    } catch (e, s) {
      addError(e, s);
    }
  }

  /// Общий cleanup для failed-путей Quick Record: стираем аудиофайл,
  /// сбрасываем uuid, эмитим ошибку и откатываем экран в idle.
  void _failQuickRecord({
    required String filePath,
    required AppFailure failure,
  }) {
    _deleteAudioFile(filePath);
    _pendingNoteUuid = null;

    safeEmit(RecordingErrorState(failure));
    _resetToIdleDelayed();
  }

  void _resetToIdleDelayed() {
    // Таймер храним, чтобы отменить при close — не эмитим после закрытия.
    _idleResetTimer?.cancel();
    _idleResetTimer = Timer(const Duration(seconds: 2), () {
      if (!isClosed) emit(const RecordingIdleState());
    });
  }

  @override
  Future<void> close() async {
    _idleResetTimer?.cancel();
    await _amplitudeSubscription?.cancel();
    _amplitudeBuffer.clear();
    // Сбрасывает `_isRecording` в singleton-сервисе, если запись была активна.
    await _recordingService.cancelRecording();
    return super.close();
  }
}
