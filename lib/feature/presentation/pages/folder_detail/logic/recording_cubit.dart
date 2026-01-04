import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_exception.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
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
///
/// Будущие улучшения:
/// - Сохранение аудио файлов с заметками
/// - Режим редактирования перед сохранением
/// - Настройки папок (язык по умолчанию, модель)
class RecordingCubit extends Cubit<RecordingState> {
  final AudioRecordingService _recordingService;
  final AsrService _asrService;
  final NoteRepository _noteRepository;

  StreamSubscription<Duration>? _durationSubscription;

  /// ID папки для записи в папку (null = Quick Record в буфер обмена)
  final String? folderId;

  RecordingCubit({
    required AudioRecordingService recordingService,
    required AsrService asrService,
    required NoteRepository noteRepository,
    this.folderId,
  }) : _recordingService = recordingService,
       _asrService = asrService,
       _noteRepository = noteRepository,
       super(const RecordingIdleState());

  // ==================== Public API ====================

  /// Начать запись
  ///
  /// Запрашивает разрешение на микрофон и начинает аудио запись.
  /// Эмитит [RecordingActiveState] с обновлениями длительности.
  Future<void> startRecording() async {
    if (state is! RecordingIdleState) return;

    try {
      await _recordingService.startRecording(
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
      emit(const RecordingErrorState(RecordingFailure.permissionDenied()));
      _resetToIdleDelayed();
    } on RecordingAlreadyActiveException {
      emit(const RecordingErrorState(RecordingFailure.alreadyRecording()));
    } catch (e, s) {
      addError(e, s);
      emit(RecordingErrorState(AppFailure.from(e, s)));
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

    try {
      await _durationSubscription?.cancel();

      final result = await _recordingService.stopRecording();

      emit(
        RecordingTranscribingState(
          filePath: result.filePath,
          duration: result.duration,
        ),
      );

      await _transcribeAndProcess(result.filePath, result.duration);
    } catch (e, s) {
      addError(e, s);
      emit(RecordingErrorState(AppFailure.from(e, s)));
      _resetToIdleDelayed();
    }
  }

  /// Отменить запись
  ///
  /// Останавливает и отбрасывает текущую запись.
  Future<void> cancelRecording() async {
    if (state is! RecordingActiveState) return;

    try {
      await _durationSubscription?.cancel();
      await _recordingService.cancelRecording();
      emit(const RecordingIdleState());
    } catch (e, s) {
      addError(e, s);
      emit(const RecordingIdleState());
    }
  }

  /// Сбросить в idle состояние (например, после показа success/error)
  void reset() {
    emit(const RecordingIdleState());
  }

  // ==================== Private методы ====================

  Future<void> _transcribeAndProcess(String filePath, Duration duration) async {
    try {
      // Проверяем инициализирован ли ASR сервис
      if (!_asrService.isInitialized) {
        emit(const RecordingErrorState(RecordingFailure.noModelSelected()));
        _resetToIdleDelayed();
        return;
      }

      // Транскрибируем аудио файл
      final asrResult = await _asrService.transcribeFile(filePath);

      // Подсчитываем слова
      final wordCount = _countWords(asrResult.text);

      if (folderId != null) {
        // Flow записи в папку: создаём заметку
        await _createNote(
          text: asrResult.text,
          duration: duration,
          language: asrResult.detectedLanguage,
          wordCount: wordCount,
        );
      } else {
        // Flow Quick Record: копируем в буфер обмена
        await _copyToClipboard(asrResult.text);
      }

      emit(
        RecordingSuccessState(
          text: asrResult.text,
          duration: duration,
          language: asrResult.detectedLanguage,
          wordCount: wordCount,
        ),
      );

      // Удаляем временный файл
      _deleteTemporaryFile(filePath);

      _resetToIdleDelayed();
    } on AsrNotInitializedException catch (e, s) {
      emit(const RecordingErrorState(RecordingFailure.noModelSelected()));
      addError(e, s);
      _resetToIdleDelayed();
    } on AsrException catch (e, s) {
      emit(const RecordingErrorState(RecordingFailure.transcriptionFailed()));
      addError(e, s);
      _resetToIdleDelayed();
    } catch (e, s) {
      addError(e, s);
      emit(RecordingErrorState(AppFailure.from(e, s)));
      _resetToIdleDelayed();
    }
  }

  Future<void> _createNote({
    required String text,
    required Duration duration,
    required int wordCount,
    String? language,
  }) async {
    if (folderId == null) return;

    await _noteRepository.create(
      text: text,
      duration: duration,
      folderUid: folderId,
      language: language ?? '',
      modelName: _asrService.currentModel?.name ?? 'Unknown',
      wordCount: wordCount,
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  void _deleteTemporaryFile(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) unawaited(file.delete());
    } catch (e, s) {
      AppFailure.from(e, s);
    }
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  void _resetToIdleDelayed() {
    // Сбрасываем в idle через небольшую задержку для показа success/error
    Future.delayed(const Duration(seconds: 2), () {
      if (!isClosed) emit(const RecordingIdleState());
    });
  }

  @override
  Future<void> close() {
    _durationSubscription?.cancel();
    return super.close();
  }
}
