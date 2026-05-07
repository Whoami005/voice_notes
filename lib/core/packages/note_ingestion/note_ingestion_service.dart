import 'dart:developer' as developer;
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/note_ingestion/note_ingestion_exception.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

/// Приём записи в систему: резолвит аудиофайл по uuid, собирает метаданные
/// и создаёт queued-заметку в БД.
///
/// Маршрутизацию в очередь транскрибации выполняет `TranscriptionQueueCubit`
/// через подписку на `NoteRepository.watchQueued` — поэтому сервис
/// **ничего не знает** об очереди.
///
/// Разделение: `RecordingCubit` не знает о БД, `NoteIngestionService` не знает
/// об очереди. Единственная точка сцепки — stream `watchQueued`.
@Singleton()
class NoteIngestionService {
  final NoteRepository _noteRepository;

  NoteIngestionService({required NoteRepository noteRepository})
    : _noteRepository = noteRepository;

  /// Принять запись: резолвить путь по [uuid] через [AudioPaths], прочитать
  /// метаданные файла и создать queued-заметку в папке [folderUid].
  ///
  /// Путь к файлу детерминированно выводится из [uuid] — сигнатура
  /// не принимает filePath, чтобы исключить рассинхрон между БД и диском.
  ///
  /// При любой ошибке — удаляет аудиофайл и бросает [NoteIngestionFailed]
  /// с упакованным [AppFailure]. Логирование у источника через `developer.log`.
  Future<void> ingest({
    required String uuid,
    required String folderUid,
    required Duration duration,
  }) async {
    final absolutePath = await AudioPaths.resolveRelativePath(
      AudioPaths.recordingRelativePath(uuid),
    );
    final file = File(absolutePath);

    // Pre-condition: recorder только что вернул успех — файл обязан
    // существовать. Если его нет, это fs-аномалия (sandbox, permission,
    // disk removed), а не валидный кейс «сохраним заметку без аудио» (в
    // отличие от cold-start seed в `TranscriptionQueueService.start()`,
    // где null audio валиден — файл мог пропасть между сессиями).
    if (!file.existsSync()) {
      developer.log(
        'NoteIngestion: audio file missing at $absolutePath',
        name: 'NoteIngestion',
      );
      throw const NoteIngestionFailed(
        StorageFailure('Не удалось сохранить заметку'),
      );
    }

    try {
      final size = await file.length();
      final audio = NoteAudioEntity(
        relativePath: AudioPaths.recordingRelativePath(uuid),
        sizeBytes: size,
        sampleRate: AudioRecordingService.sampleRate,
        duration: duration,
      );

      await _noteRepository.createQueuedAudioNote(
        uid: uuid,
        folderUid: folderUid,
        sourceDuration: duration,
        audio: audio,
      );
      // Файл НЕ удаляется в happy path — он становится оригиналом заметки.
      // Очередь удалит его в `completeTranscription` по `keepOriginals`.
    } catch (e, s) {
      developer.log(
        'NoteIngestion: createQueued failed for $uuid',
        error: e,
        stackTrace: s,
        name: 'NoteIngestion',
      );
      await _deleteFileSafely(absolutePath);
      throw NoteIngestionFailed(AppFailure.from(e, s));
    }
  }

  Future<void> _deleteFileSafely(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
