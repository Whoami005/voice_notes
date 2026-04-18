import 'package:equatable/equatable.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';

class NoteEntity extends Equatable {
  final String uuid;
  final String? folderId;
  final String text;
  final Duration duration;
  final String modelName;
  final String language;
  final int wordCount;
  final List<TagEntity> tags;
  final NoteAudioEntity? audio;

  final TranscriptionStatus status;
  final TranscriptionFailureReason? failureReason;

  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteEntity({
    required this.uuid,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.duration,
    required this.modelName,
    required this.language,
    required this.wordCount,
    required this.status,
    this.folderId,
    this.tags = const [],
    this.audio,
    this.failureReason,
  });

  bool get isCompleted => status.isCompleted;

  bool get isQueued => status.isQueued;

  bool get isTranscribing => status.isTranscribing;

  bool get isFailed => status.isFailed;

  bool get isCancelled => status.isCancelled;

  @override
  List<Object?> get props => [
    uuid,
    folderId,
    text,
    createdAt,
    updatedAt,
    duration,
    modelName,
    language,
    wordCount,
    tags,
    audio,
    status,
    failureReason,
  ];

  NoteEntity copyWith({
    String? uuid,
    String? folderId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    Duration? duration,
    String? modelName,
    String? language,
    int? wordCount,
    List<TagEntity>? tags,
    NoteAudioEntity? Function()? audio,
    TranscriptionStatus? status,
    TranscriptionFailureReason? Function()? failureReason,
  }) {
    return NoteEntity(
      uuid: uuid ?? this.uuid,
      folderId: folderId ?? this.folderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      duration: duration ?? this.duration,
      modelName: modelName ?? this.modelName,
      language: language ?? this.language,
      wordCount: wordCount ?? this.wordCount,
      tags: tags ?? this.tags,
      audio: audio != null ? audio() : this.audio,
      status: status ?? this.status,
      failureReason: failureReason != null
          ? failureReason()
          : this.failureReason,
    );
  }
}
