import 'package:objectbox/objectbox.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';

@Entity()
class TagObject {
  @Id()
  int id;

  @Unique()
  String name; // ВАЖНО: хранить в lowercase!

  int? colorValue;

  @Property(type: PropertyType.dateNanoUtc)
  DateTime createdAt;

  @Backlink('tags')
  final notes = ToMany<NoteObject>();

  TagObject({
    required this.name,
    required this.createdAt,
    this.id = 0,
    this.colorValue,
  });
}
