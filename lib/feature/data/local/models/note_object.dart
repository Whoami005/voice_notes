import 'package:objectbox/objectbox.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
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

  int durationMs;
  String modelName;
  String language;
  int wordCount;
  bool hasAudio;

  final folder = ToOne<FolderObject>();
  final tags = ToMany<TagObject>();

  NoteObject({
    required this.uid,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.durationMs,
    required this.modelName,
    required this.language,
    required this.wordCount,
    this.id = 0,
    this.hasAudio = true,
  });
}
