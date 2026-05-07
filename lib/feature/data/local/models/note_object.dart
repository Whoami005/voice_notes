import 'package:objectbox/objectbox.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_transcription_segment_object.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';

@Entity()
class NoteObject {
  @Id()
  int id;

  @Unique()
  String uid;

  String text;

  @Property(type: PropertyType.dateNanoUtc)
  @Index()
  DateTime createdAt;

  @Property(type: PropertyType.dateNanoUtc)
  @Index()
  DateTime updatedAt;

  int originTypeValue;

  int? sourceDurationMs;

  String? transcriptionModelId;

  String? transcriptionLanguageCode;

  int? transcriptionTaskTypeValue;

  @Property(type: PropertyType.dateNanoUtc)
  DateTime? transcribedAt;

  int? transcriptionProcessingTimeMs;

  int? transcriptionStrategyValue;

  bool? transcriptionUsedVad;

  bool? transcriptionFellBackFromVad;

  String? transcriptionEmotionLabel;

  String? transcriptionEventLabel;

  bool? transcriptionUsedItn;

  bool? transcriptionUsedPunctuation;

  @Index()
  int statusValue;

  int? failureReasonValue;

  final folder = ToOne<FolderObject>();
  final tags = ToMany<TagObject>();
  final audio = ToOne<NoteAudioObject>();
  @Backlink('note')
  final transcriptionSegments = ToMany<NoteTranscriptionSegmentObject>();

  NoteObject({
    required this.uid,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.originTypeValue,
    required this.statusValue,
    this.sourceDurationMs,
    this.transcriptionModelId,
    this.transcriptionLanguageCode,
    this.transcriptionTaskTypeValue,
    this.transcribedAt,
    this.transcriptionProcessingTimeMs,
    this.transcriptionStrategyValue,
    this.transcriptionUsedVad,
    this.transcriptionFellBackFromVad,
    this.transcriptionEmotionLabel,
    this.transcriptionEventLabel,
    this.transcriptionUsedItn,
    this.transcriptionUsedPunctuation,
    this.failureReasonValue,
    this.id = 0,
  });
}
