import 'dart:convert';

import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/data/local/models/note_transcription_segment_object.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_segment_entity.dart';

abstract final class NoteTranscriptionSegmentMapper {
  static NoteTranscriptionSegmentEntity toDomain(
    NoteTranscriptionSegmentObject object,
  ) {
    return NoteTranscriptionSegmentEntity(
      index: object.index,
      text: object.text,
      start: Duration(milliseconds: object.startMs),
      end: Duration(milliseconds: object.endMs),
      languageCode: object.languageCode,
      tokens: _decodeStringList(object.tokensJson),
      tokenTimestamps: _decodeDurationList(object.tokenTimestampsMsJson),
    );
  }

  static List<NoteTranscriptionSegmentEntity> toDomainList(
    List<NoteTranscriptionSegmentObject> objects,
  ) {
    final entities = [for (final object in objects) toDomain(object)]
      ..sort((a, b) => a.index.compareTo(b.index));

    return entities;
  }

  static NoteTranscriptionSegmentObject toEntity({
    required NoteTranscriptionSegmentEntity entity,
    required NoteObject note,
  }) {
    return NoteTranscriptionSegmentObject(
      index: entity.index,
      text: entity.text,
      startMs: entity.start.inMilliseconds,
      endMs: entity.end.inMilliseconds,
      languageCode: entity.languageCode,
      tokensJson: _encodeStringList(entity.tokens),
      tokenTimestampsMsJson: _encodeDurationList(entity.tokenTimestamps),
    )..note.target = note;
  }

  static String? _encodeStringList(List<String>? items) {
    if (items == null) return null;

    return jsonEncode(items);
  }

  static String? _encodeDurationList(List<Duration>? items) {
    if (items == null) return null;

    return jsonEncode([for (final item in items) item.inMilliseconds]);
  }

  static List<String>? _decodeStringList(String? json) {
    if (json == null || json.isEmpty) return null;

    return List<String>.from(jsonDecode(json) as List<dynamic>);
  }

  static List<Duration>? _decodeDurationList(String? json) {
    if (json == null || json.isEmpty) return null;

    return [
      for (final value in jsonDecode(json) as List<dynamic>)
        Duration(milliseconds: value as int),
    ];
  }
}
