import 'package:objectbox/objectbox.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
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

  @Property(type: PropertyType.dateNanoUtc)
  DateTime? transcribedAt;

  @Index()
  int statusValue;

  int? failureReasonValue;

  final folder = ToOne<FolderObject>();
  final tags = ToMany<TagObject>();
  final audio = ToOne<NoteAudioObject>();

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
    this.transcribedAt,
    this.failureReasonValue,
    this.id = 0,
  });
}
