import 'package:equatable/equatable.dart';
import 'package:voice_notes/feature/domain/entities/note_origin_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';

class NoteEntity extends Equatable {
  static final _whitespaceRegex = RegExp(r'\s+');

  final String uuid;
  final String? folderId;
  final String text;
  final NoteOriginEntity origin;
  final List<TagEntity> tags;
  final TranscriptionStatus status;
  final TranscriptionFailureReason? failureReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayId {
    final normalizedUuid = uuid.replaceAll('-', '').toUpperCase();
    final shortPart = normalizedUuid.length <= 8
        ? normalizedUuid
        : normalizedUuid.substring(0, 8);

    return 'VN-$shortPart';
  }

  String get titleOrDisplayId {
    final trimmedText = text.trim();

    return trimmedText.isEmpty ? displayId : trimmedText;
  }

  int get wordCount {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return 0;

    return trimmedText.split(_whitespaceRegex).length;
  }

  const NoteEntity({
    required this.uuid,
    required this.text,
    required this.origin,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.folderId,
    this.tags = const [],
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
    origin,
    createdAt,
    updatedAt,
    wordCount,
    tags,
    status,
    failureReason,
  ];

  NoteEntity copyWith({
    String? uuid,
    String? folderId,
    String? text,
    NoteOriginEntity? origin,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TagEntity>? tags,
    TranscriptionStatus? status,
    TranscriptionFailureReason? Function()? failureReason,
  }) {
    return NoteEntity(
      uuid: uuid ?? this.uuid,
      folderId: folderId ?? this.folderId,
      text: text ?? this.text,
      origin: origin ?? this.origin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      failureReason: failureReason != null
          ? failureReason()
          : this.failureReason,
    );
  }
}
