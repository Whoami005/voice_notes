import 'package:objectbox/objectbox.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';

@Entity()
class NoteTranscriptionSegmentObject {
  @Id()
  int id;

  @Index()
  int index;

  String text;

  int startMs;

  int endMs;

  String? languageCode;

  String? tokensJson;

  String? tokenTimestampsMsJson;

  final note = ToOne<NoteObject>();

  NoteTranscriptionSegmentObject({
    required this.index,
    required this.text,
    required this.startMs,
    required this.endMs,
    this.languageCode,
    this.tokensJson,
    this.tokenTimestampsMsJson,
    this.id = 0,
  });
}
