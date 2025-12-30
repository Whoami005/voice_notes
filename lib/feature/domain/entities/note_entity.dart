import 'package:voice_notes/feature/domain/entities/tag_entity.dart';

class NoteEntity {
  final String id;
  final String? folderId;
  final String text;
  final Duration duration;
  final String modelName;
  final String language;
  final int wordCount;
  final List<TagEntity> tags;
  final bool hasAudio;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteEntity({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.duration,
    required this.modelName,
    required this.language,
    required this.wordCount,
    this.folderId,
    this.tags = const [],
    this.hasAudio = true,
  });

  NoteEntity copyWith({
    String? id,
    String? folderId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    Duration? duration,
    String? modelName,
    String? language,
    int? wordCount,
    List<TagEntity>? tags,
    bool? hasAudio,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      duration: duration ?? this.duration,
      modelName: modelName ?? this.modelName,
      language: language ?? this.language,
      wordCount: wordCount ?? this.wordCount,
      tags: tags ?? this.tags,
      hasAudio: hasAudio ?? this.hasAudio,
    );
  }
}
