import 'package:equatable/equatable.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_meta_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_segment_entity.dart';
import 'package:voice_notes/feature/domain/enums/note_origin_type.dart';

sealed class NoteOriginEntity extends Equatable {
  const NoteOriginEntity();

  NoteOriginType get type;

  bool get isManual => this is ManualNoteOriginEntity;

  bool get isAudio => this is AudioNoteOriginEntity;

  AudioNoteOriginEntity? get audioOrNull => switch (this) {
    final AudioNoteOriginEntity audioOrigin => audioOrigin,
    _ => null,
  };

  Duration? get sourceDuration => audioOrNull?.sourceDuration;

  Duration get sourceDurationOrZero => sourceDuration ?? Duration.zero;

  NoteTranscriptionMetaEntity? get transcription => audioOrNull?.transcription;

  List<NoteTranscriptionSegmentEntity>? get transcriptionSegments =>
      audioOrNull?.transcriptionSegments;

  AsrModelIdEnum? get transcriptionModelId => transcription?.modelId;

  String? get languageCode => transcription?.languageCode;

  String? get detectedLanguageCode => transcription?.detectedLanguageCode;

  DateTime? get transcribedAt => transcription?.transcribedAt;

  NoteAudioEntity? get audio => audioOrNull?.audio;
}

class ManualNoteOriginEntity extends NoteOriginEntity {
  const ManualNoteOriginEntity();

  @override
  NoteOriginType get type => NoteOriginType.manual;

  @override
  List<Object?> get props => [type];
}

class AudioNoteOriginEntity extends NoteOriginEntity {
  @override
  final Duration sourceDuration;

  @override
  final NoteAudioEntity? audio;

  @override
  final NoteTranscriptionMetaEntity? transcription;

  @override
  final List<NoteTranscriptionSegmentEntity>? transcriptionSegments;

  const AudioNoteOriginEntity({
    required this.sourceDuration,
    this.audio,
    this.transcription,
    this.transcriptionSegments,
  });

  @override
  NoteOriginType get type => NoteOriginType.audio;

  AudioNoteOriginEntity copyWith({
    Duration? sourceDuration,
    NoteAudioEntity? Function()? audio,
    NoteTranscriptionMetaEntity? Function()? transcription,
    List<NoteTranscriptionSegmentEntity>? Function()? transcriptionSegments,
  }) {
    return AudioNoteOriginEntity(
      sourceDuration: sourceDuration ?? this.sourceDuration,
      audio: audio != null ? audio() : this.audio,
      transcription: transcription != null
          ? transcription()
          : this.transcription,
      transcriptionSegments: transcriptionSegments != null
          ? transcriptionSegments()
          : this.transcriptionSegments,
    );
  }

  @override
  List<Object?> get props => [
    type,
    sourceDuration,
    audio,
    transcription,
    transcriptionSegments,
  ];
}
