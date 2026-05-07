import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/feature/data/local/mappers/note_audio_mapper.dart';
import 'package:voice_notes/feature/data/local/mappers/note_transcription_segment_mapper.dart';
import 'package:voice_notes/feature/data/local/mappers/tag_mapper.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_origin_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_meta_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_segment_entity.dart';
import 'package:voice_notes/feature/domain/enums/note_origin_type.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';
import 'package:voice_notes/feature/domain/enums/transcription_task_type.dart';

abstract final class NoteMapper {
  static NoteEntity toDomain(NoteObject e) {
    final audioObj = e.audio.target;

    return NoteEntity(
      uuid: e.uid,
      folderId: e.folder.target?.uid,
      text: e.text,
      origin: _toOrigin(e, audioObj),
      tags: TagMapper.toDomainList(e.tags.toList()),
      status: TranscriptionStatus.fromValue(e.statusValue),
      failureReason: e.failureReasonValue == null
          ? null
          : TranscriptionFailureReason.fromValue(e.failureReasonValue!),
      createdAt: e.createdAt.toLocal(),
      updatedAt: e.updatedAt.toLocal(),
    );
  }

  static NoteObject toEntity(NoteEntity n, {int id = 0}) {
    return NoteObject(
      id: id,
      uid: n.uuid,
      text: n.text,
      originTypeValue: n.origin.type.value,
      sourceDurationMs: n.origin.sourceDuration?.inMilliseconds,
      transcriptionModelId: n.origin.transcription?.modelId.value,
      transcriptionLanguageCode: n.origin.transcription?.languageCode,
      transcribedAt: n.origin.transcription?.transcribedAt,
      transcriptionTaskTypeValue: n.origin.transcription?.taskType.value,
      transcriptionProcessingTimeMs:
          n.origin.transcription?.processingTime.inMilliseconds,
      transcriptionStrategyValue: n.origin.transcription?.strategyUsed.index,
      transcriptionUsedVad: n.origin.transcription?.usedVad,
      transcriptionFellBackFromVad: n.origin.transcription?.fellBackFromVad,
      transcriptionEmotionLabel: n.origin.transcription?.emotionLabel,
      transcriptionEventLabel: n.origin.transcription?.eventLabel,
      transcriptionUsedItn: n.origin.transcription?.usedItn,
      transcriptionUsedPunctuation: n.origin.transcription?.usedPunctuation,
      statusValue: n.status.value,
      failureReasonValue: n.failureReason?.value,
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
    );
    // NB: audio relation НЕ устанавливается здесь — это будет делать
    // NoteLocalDataSource.saveWithRelations, когда появится фактический
    // flow создания записи с сохранённым аудио.
  }

  /// Обновляет существующую entity значениями из domain-модели.
  ///
  /// **Не трогает audio relation** — это делается в
  /// `NoteLocalDataSourceImpl.updateWithTags` внутри транзакции, чтобы
  /// безопасно удалять `NoteAudioObject` при clear audio (без orphan).
  static void updateEntity(NoteObject entity, NoteEntity note) {
    entity
      ..text = note.text
      ..updatedAt = note.updatedAt
      ..originTypeValue = note.origin.type.value
      ..sourceDurationMs = note.origin.sourceDuration?.inMilliseconds
      ..transcriptionModelId = note.origin.transcription?.modelId.value
      ..transcriptionLanguageCode = note.origin.transcription?.languageCode
      ..transcriptionTaskTypeValue = note.origin.transcription?.taskType.value
      ..transcribedAt = note.origin.transcription?.transcribedAt
      ..transcriptionProcessingTimeMs =
          note.origin.transcription?.processingTime.inMilliseconds
      ..transcriptionStrategyValue =
          note.origin.transcription?.strategyUsed.index
      ..transcriptionUsedVad = note.origin.transcription?.usedVad
      ..transcriptionFellBackFromVad =
          note.origin.transcription?.fellBackFromVad
      ..transcriptionEmotionLabel = note.origin.transcription?.emotionLabel
      ..transcriptionEventLabel = note.origin.transcription?.eventLabel
      ..transcriptionUsedItn = note.origin.transcription?.usedItn
      ..transcriptionUsedPunctuation =
          note.origin.transcription?.usedPunctuation
      ..statusValue = note.status.value
      ..failureReasonValue = note.failureReason?.value;
  }

  static List<NoteEntity> toDomainList(List<NoteObject> entities) {
    return [for (final e in entities) toDomain(e)];
  }

  static NoteOriginEntity _toOrigin(
    NoteObject object,
    NoteAudioObject? audioObject,
  ) {
    final originType = NoteOriginType.fromValue(object.originTypeValue);

    return switch (originType) {
      NoteOriginType.manual => const ManualNoteOriginEntity(),
      NoteOriginType.audio => AudioNoteOriginEntity(
        sourceDuration: Duration(
          milliseconds: _requireSourceDurationMs(object.sourceDurationMs),
        ),
        audio: audioObject == null
            ? null
            : NoteAudioMapper.toDomain(audioObject),
        transcription: _toTranscription(object),
        transcriptionSegments: _toTranscriptionSegments(object),
      ),
    };
  }

  static NoteTranscriptionMetaEntity? _toTranscription(NoteObject object) {
    final modelIdValue = object.transcriptionModelId;
    final transcribedAt = object.transcribedAt;
    if (modelIdValue == null || transcribedAt == null) return null;

    final modelId = AsrModelIdEnum.fromValue(modelIdValue);
    if (modelId == null) {
      throw StateError('Unknown ASR model id: $modelIdValue');
    }

    return NoteTranscriptionMetaEntity(
      modelId: modelId,
      languageCode: object.transcriptionLanguageCode,
      taskType: TranscriptionTaskType.fromValue(
        _requireTranscriptionTaskTypeValue(object.transcriptionTaskTypeValue),
      ),
      transcribedAt: transcribedAt.toLocal(),
      processingTime: Duration(
        milliseconds: _requireTranscriptionProcessingTimeMs(
          object.transcriptionProcessingTimeMs,
        ),
      ),
      strategyUsed: _requireTranscriptionStrategy(
        object.transcriptionStrategyValue,
      ),
      usedVad: _requireTranscriptionUsedVad(object.transcriptionUsedVad),
      fellBackFromVad: _requireTranscriptionFellBackFromVad(
        object.transcriptionFellBackFromVad,
      ),
      emotionLabel: object.transcriptionEmotionLabel,
      eventLabel: object.transcriptionEventLabel,
      usedItn: object.transcriptionUsedItn,
      usedPunctuation: object.transcriptionUsedPunctuation,
    );
  }

  static List<NoteTranscriptionSegmentEntity>? _toTranscriptionSegments(
    NoteObject object,
  ) {
    final segments = object.transcriptionSegments.toList();
    if (segments.isEmpty) return null;

    return NoteTranscriptionSegmentMapper.toDomainList(segments);
  }

  static int _requireSourceDurationMs(int? sourceDurationMs) {
    if (sourceDurationMs != null) return sourceDurationMs;

    throw StateError('Audio note origin requires sourceDurationMs');
  }

  static int _requireTranscriptionTaskTypeValue(int? taskTypeValue) {
    if (taskTypeValue != null) return taskTypeValue;

    throw StateError('Transcribed audio note requires transcriptionTaskType');
  }

  static int _requireTranscriptionProcessingTimeMs(int? processingTimeMs) {
    if (processingTimeMs != null) return processingTimeMs;

    throw StateError(
      'Transcribed audio note requires transcriptionProcessingTimeMs',
    );
  }

  static AsrTranscriptionStrategy _requireTranscriptionStrategy(
    int? strategyValue,
  ) {
    if (strategyValue != null) {
      return AsrTranscriptionStrategy.values[strategyValue];
    }

    throw StateError('Transcribed audio note requires transcriptionStrategy');
  }

  static bool _requireTranscriptionUsedVad(bool? usedVad) {
    if (usedVad != null) return usedVad;

    throw StateError('Transcribed audio note requires transcriptionUsedVad');
  }

  static bool _requireTranscriptionFellBackFromVad(bool? fellBackFromVad) {
    if (fellBackFromVad != null) return fellBackFromVad;

    throw StateError(
      'Transcribed audio note requires transcriptionFellBackFromVad',
    );
  }
}
