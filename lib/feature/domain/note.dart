class Note {
  final String id;
  final String text;
  final DateTime createdAt;
  final Duration duration;
  final String modelName;
  final String language;
  final int wordCount;
  final List<String> tags;
  final bool hasAudio;

  const Note({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.duration,
    required this.modelName,
    required this.language,
    required this.wordCount,
    this.tags = const [],
    this.hasAudio = true,
  });

  Note copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    Duration? duration,
    String? modelName,
    String? language,
    int? wordCount,
    List<String>? tags,
    bool? hasAudio,
  }) {
    return Note(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
      modelName: modelName ?? this.modelName,
      language: language ?? this.language,
      wordCount: wordCount ?? this.wordCount,
      tags: tags ?? this.tags,
      hasAudio: hasAudio ?? this.hasAudio,
    );
  }
}
