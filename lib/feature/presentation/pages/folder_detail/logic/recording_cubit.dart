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
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/uuid/uuid_manager.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
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
///
/// Будущие улучшения:
/// - Сохранение аудио файлов с заметками
/// - Режим редактирования перед сохранением
/// - Настройки папок (язык по умолчанию, модель)
class RecordingCubit extends Cubit<RecordingState> {
  final AudioRecordingService _recordingService;
  final AsrService _asrService;
  final NoteRepository _noteRepository;
  final RecordingPreferences _preferences;

  StreamSubscription<Duration>? _durationSubscription;

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
    required RecordingPreferences preferences,
    this.folderId,
  }) : _recordingService = recordingService,
       _asrService = asrService,
       _noteRepository = noteRepository,
       _preferences = preferences,
       super(const RecordingIdleState());

  // ==================== Public API ====================

  /// Начать запись
  ///
  /// Запрашивает разрешение на микрофон и начинает аудио запись.
  /// Эмитит [RecordingActiveState] с обновлениями длительности.
  Future<void> startRecording() async {
    if (state is! RecordingIdleState) return;

    try {
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

      // Транскрибируем в фоне — заметка сохранится
      // даже если пользователь выйдет
      unawaited(
        _transcribeAndProcess(
          noteUuid: noteUuid,
          filePath: result.filePath,
          duration: result.duration,
        ),
      );
    } catch (e, s) {
      if (isClosed) return;

      _pendingNoteUuid = null;
      addError(e, s);
      emit(RecordingErrorState(AppFailure.from(e, s)));
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
      final wordCount = _countWords(trimmedText);

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
      addError(e, s);
      emit(RecordingErrorState(AppFailure.from(e, s)));
      _resetToIdleDelayed();
    }
  }

  // ==================== Private методы ====================

  Future<void> _transcribeAndProcess({
    required String noteUuid,
    required String filePath,
    required Duration duration,
  }) async {
    try {
      // Проверяем инициализирован ли ASR сервис
      if (!_asrService.isInitialized) {
        _deleteAudioFile(filePath);
        _safeEmit(
          const RecordingErrorState(RecordingFailure.noModelSelected()),
        );
        _resetToIdleDelayed();
        return;
      }

      // Транскрибируем аудио файл
      final asrResult = await _asrService.transcribeFile(filePath);

      // Подсчитываем слова
      final wordCount = _countWords(asrResult.text);

      if (folderId != null) {
        // Голосовая заметка в папке — сохраняем с audio-метаданными.
        // Для Quick Record (folderId == null) файл всё равно удаляем —
        // это режим копирования в буфер обмена, не создание заметки.
        await _createVoiceNote(
          noteUuid: noteUuid,
          filePath: filePath,
          duration: duration,
          language: asrResult.detectedLanguage,
          text: asrResult.text,
          wordCount: wordCount,
        );
      } else {
        await _copyToClipboard(asrResult.text);
        _deleteAudioFile(filePath);
      }

      _pendingNoteUuid = null;
      _safeEmit(
        RecordingSuccessState(
          text: asrResult.text,
          duration: duration,
          language: asrResult.detectedLanguage,
          wordCount: wordCount,
        ),
      );

      _resetToIdleDelayed();
    } on AsrNotInitializedException catch (e, s) {
      _deleteAudioFile(filePath);
      _pendingNoteUuid = null;
      addError(e, s);
      _safeEmit(const RecordingErrorState(RecordingFailure.noModelSelected()));
      _resetToIdleDelayed();
    } on AsrException catch (e, s) {
      _deleteAudioFile(filePath);
      _pendingNoteUuid = null;
      addError(e, s);
      _safeEmit(
        const RecordingErrorState(RecordingFailure.transcriptionFailed()),
      );
      _resetToIdleDelayed();
    } catch (e, s) {
      _deleteAudioFile(filePath);
      _pendingNoteUuid = null;
      addError(e, s);
      _safeEmit(RecordingErrorState(AppFailure.from(e, s)));
      _resetToIdleDelayed();
    }
  }

  Future<void> _createVoiceNote({
    required String noteUuid,
    required String filePath,
    required Duration duration,
    required int wordCount,
    required String text,
    String? language,
  }) async {
    final currentModel = _asrService.currentModel;
    if (folderId == null || currentModel == null) {
      // Без активной модели не сохраняем заметку — но и файл удаляем,
      // чтобы не оставить сироту.
      _deleteAudioFile(filePath);
      return;
    }

    // Пользовательская настройка: сохранять оригинал или выбросить после
    // транскрибации. Влияет только на новые записи.
    final keepOriginal = _preferences.keepOriginals;

    NoteAudioEntity? audio;
    if (keepOriginal) {
      audio = await _buildAudioEntity(
        noteUuid: noteUuid,
        filePath: filePath,
        duration: duration,
      );
    } else {
      _deleteAudioFile(filePath);
    }

    await _noteRepository.create(
      uid: noteUuid,
      text: text,
      duration: duration,
      folderUid: folderId,
      language: language ?? '',
      modelName: currentModel.name,
      wordCount: wordCount,
      audio: audio,
    );
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

  /// Безопасный emit — игнорирует если cubit закрыт
  void _safeEmit(RecordingState state) {
    if (!isClosed) emit(state);
  }

  @override
  Future<void> close() async {
    await _durationSubscription?.cancel();
    // Отменяем активную запись (сбрасывает _isRecording в singleton)
    await _recordingService.cancelRecording();
    return super.close();
  }
}
