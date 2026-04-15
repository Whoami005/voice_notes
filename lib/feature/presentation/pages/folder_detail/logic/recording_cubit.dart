import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/extensions/string_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_exception.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_service.dart';
import 'package:voice_notes/core/packages/uuid/uuid_manager.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/enums/recording_state.dart'
    show RecordingInputState;
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'recording_state.dart';

/// Cubit для управления записью и транскрибацией
///
/// Обрабатывает:
/// - Запись аудио через AudioRecordingService
/// - Транскрибацию через AsrService
/// - Создание заметок в папках или копирование в буфер обмена
class RecordingCubit extends BaseCubit<RecordingState> {
  final AudioRecordingService _recordingService;
  final AsrService _asrService;
  final NoteRepository _noteRepository;
  final AudioPlaybackController _playbackController;
  final TranscriptionQueueService _queue;

  StreamSubscription<Duration>? _durationSubscription;
  Timer? _idleResetTimer;

  /// ID папки для записи в папку (null = Quick Record в буфер обмена)
  final String? folderId;

  /// Uuid будущей заметки, сгенерированный в момент startRecording.
  /// Используется как имя файла и как uid создаваемой заметки, чтобы
  /// запись и её метаданные были связаны стабильным идентификатором.
  String? _pendingNoteUuid;

  RecordingCubit({
    required AudioRecordingService recordingService,
    required AsrService asrService,
    required NoteRepository noteRepository,
    required AudioPlaybackController playbackController,
    required TranscriptionQueueService queue,
    this.folderId,
  }) : _recordingService = recordingService,
       _asrService = asrService,
       _noteRepository = noteRepository,
       _playbackController = playbackController,
       _queue = queue,
       super(const RecordingIdleState());

  // ==================== Public API ====================

  /// Начать запись
  ///
  /// Запрашивает разрешение на микрофон и начинает аудио запись.
  /// Эмитит [RecordingActiveState] с обновлениями длительности.
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

      emit(const RecordingActiveState());

      // Подписываемся на обновления длительности
      _durationSubscription = _recordingService.durationStream.listen((
        duration,
      ) {
        if (state is RecordingActiveState) {
          emit(RecordingActiveState(duration: duration));
        }
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

  /// Остановить запись и начать транскрибацию
  ///
  /// Останавливает запись, затем транскрибирует аудио.
  /// Для записи в папку: создаёт заметку.
  /// Для Quick Record: копирует текст в буфер обмена.
  Future<void> stopRecording() async {
    if (state is! RecordingActiveState) return;

    final noteUuid = _pendingNoteUuid;
    if (noteUuid == null) return;

    try {
      await _durationSubscription?.cancel();

      final result = await _recordingService.stopRecording();

      // Если cubit закрылся во время остановки записи — выходим
      if (isClosed) return;

      emit(
        RecordingTranscribingState(
          filePath: result.filePath,
          duration: result.duration,
        ),
      );

      // Для folder-режима: сразу создаём pending-заметку и отдаём в очередь,
      // UI освобождается мгновенно (messenger-like UX). Quick Record остаётся
      // синхронным — он не создаёт заметку, только транскрибирует в clipboard.
      unawaited(
        _scheduleTranscription(
          noteUuid: noteUuid,
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

  /// Отменить запись
  ///
  /// Останавливает и отбрасывает текущую запись. Файл удаляется сервисом.
  Future<void> cancelRecording() async {
    if (state is! RecordingActiveState) return;

    try {
      await _durationSubscription?.cancel();
      await _recordingService.cancelRecording();

      _pendingNoteUuid = null;
      emit(const RecordingIdleState());
    } catch (e, s) {
      _pendingNoteUuid = null;
      addError(e, s);
      emit(const RecordingIdleState());
    }
  }

  /// Сбросить в idle состояние (например, после показа success/error)
  void reset() {
    emit(const RecordingIdleState());
  }

  /// Создать заметку из текста (без аудио)
  ///
  /// Используется для текстового ввода вместо голосовой записи.
  /// Эмитит [RecordingSuccessState] при успехе или
  /// [RecordingErrorState] при ошибке.
  Future<void> createTextNote(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || state is! RecordingIdleState) return;
    if (folderId == null) return;

    try {
      final wordCount = trimmedText.wordCount;

      await _noteRepository.create(
        text: trimmedText,
        duration: Duration.zero,
        folderUid: folderId,
        language: '',
        modelName: 'TextInput',
        wordCount: wordCount,
      );

      emit(
        RecordingSuccessState(
          text: trimmedText,
          duration: Duration.zero,
          wordCount: wordCount,
        ),
      );

      _resetToIdleDelayed();
    } catch (e, s) {
      safeEmit(RecordingErrorState(logError(e, s)));
      _resetToIdleDelayed();
    }
  }

  // ==================== Private методы ====================

  /// Планирование транскрибации после остановки записи.
  ///
  /// - Folder-режим: мгновенно создаём pending-заметку с аудио, ставим в
  ///   очередь и возвращаем UI в idle. Транскрибация и финальный статус —
  ///   задача [TranscriptionQueueService].
  /// - Quick Record (`folderId == null`): синхронный путь через ASR →
  ///   clipboard. Заметка не создаётся.
  Future<void> _scheduleTranscription({
    required String noteUuid,
    required String filePath,
    required Duration duration,
  }) async {
    final folder = folderId;
    if (folder == null) {
      await _processQuickRecord(
        noteUuid: noteUuid,
        filePath: filePath,
        duration: duration,
      );
      return;
    }

    try {
      // Аудио сохраняем до ready — даже при keepOriginals=false. Нужно для
      // retry на failed; очередь удалит файл при переходе в ready.
      final audio = await _buildAudioEntity(
        noteUuid: noteUuid,
        filePath: filePath,
        duration: duration,
      );

      if (audio == null) {
        _failRecording(
          filePath: filePath,
          failure: const RecordingFailure.transcriptionFailed(),
        );
        return;
      }

      await _noteRepository.createPending(
        uid: noteUuid,
        folderUid: folder,
        duration: duration,
        audio: audio,
      );

      await _queue.enqueue(noteUuid);

      _pendingNoteUuid = null;
      // Success-state не эмитим — UX-фидбек даёт pending-бабл в списке.
      _idleResetTimer?.cancel();
      safeEmit(const RecordingIdleState());
    } catch (e, s) {
      _failRecording(filePath: filePath, failure: logError(e, s));
    }
  }

  /// Quick Record: синхронная транскрибация и копирование в буфер обмена.
  /// Заметка не создаётся. Если очередь не пуста — команда транскрибации
  /// всё равно встанет в хвост FIFO-команд изолята; пользователь увидит
  /// ожидание через toast в UI (показывается в `VoiceRecordButton`).
  Future<void> _processQuickRecord({
    required String noteUuid,
    required String filePath,
    required Duration duration,
  }) async {
    try {
      if (!_asrService.isInitialized) {
        _failRecording(
          filePath: filePath,
          failure: const RecordingFailure.noModelSelected(),
        );
        return;
      }

      final asrResult = await _asrService.transcribeFile(filePath);

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
      _failRecording(
        filePath: filePath,
        failure: const RecordingFailure.noModelSelected(),
      );
    } on AsrException catch (e, s) {
      addError(e, s);
      _failRecording(
        filePath: filePath,
        failure: const RecordingFailure.transcriptionFailed(),
      );
    } catch (e, s) {
      _failRecording(filePath: filePath, failure: logError(e, s));
    }
  }

  /// Собирает [NoteAudioEntity] из фактического файла на диске.
  /// Если файл недоступен — возвращает null, и заметка будет сохранена
  /// без аудио (graceful degradation).
  Future<NoteAudioEntity?> _buildAudioEntity({
    required String noteUuid,
    required String filePath,
    required Duration duration,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final size = await file.length();

      return NoteAudioEntity(
        relativePath: AudioPaths.recordingRelativePath(noteUuid),
        sizeBytes: size,
        sampleRate: AudioRecordingService.sampleRate,
        duration: duration,
      );
    } catch (e, s) {
      addError(e, s);
      return null;
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Удаляет аудиофайл записи. Вызывается при отказе от сохранения —
  /// ASR-ошибка, отсутствие активной модели, Quick Record в буфер обмена.
  /// В happy path файл НЕ удаляется — он становится оригиналом заметки.
  void _deleteAudioFile(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) unawaited(file.delete());
    } catch (e, s) {
      addError(e, s);
    }
  }

  /// Общий cleanup для failed-путей: стираем аудиофайл, сбрасываем uuid,
  /// эмитим ошибку и откатываем экран в idle.
  void _failRecording({required String filePath, required AppFailure failure}) {
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
    await _durationSubscription?.cancel();
    // Отменяем активную запись (сбрасывает _isRecording в singleton)
    await _recordingService.cancelRecording();
    return super.close();
  }
}
