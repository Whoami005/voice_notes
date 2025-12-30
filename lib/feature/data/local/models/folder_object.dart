import 'package:objectbox/objectbox.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';

@Entity()
class FolderObject {
  @Id()
  int id;

  @Unique()
  String uid;

  @Index()
  String name;

  String? description;

  int colorValue;

  String iconRef;

  @Property(type: PropertyType.dateNanoUtc)
  @Index()
  DateTime updatedAt;

  @Property(type: PropertyType.dateNanoUtc)
  @Index()
  DateTime createdAt;

  @Backlink('folder')
  final notes = ToMany<NoteObject>();

  FolderObject({
    required this.uid,
    required this.name,
    required this.colorValue,
    required this.iconRef,
    required this.updatedAt,
    required this.createdAt,
    this.id = 0,
    this.description,
  });
}
