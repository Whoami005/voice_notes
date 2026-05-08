import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox.g.dart';
import 'package:voice_notes/core/packages/db/object_box/objectbox_database.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/data/local/models/note_transcription_segment_object.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';

abstract interface class AppDataRestoreLocalDataSource {
  Future<void> replaceAll({
    required List<FolderObject> folders,
    required List<TagObject> tags,
    required List<NoteAudioObject> audio,
    required List<NoteObject> notes,
    required List<NoteTranscriptionSegmentObject> segments,
  });
}

@Singleton(as: AppDataRestoreLocalDataSource)
class AppDataRestoreLocalDataSourceImpl
    implements AppDataRestoreLocalDataSource {
  final DatabaseClient _db;

  AppDataRestoreLocalDataSourceImpl(this._db);

  @override
  Future<void> replaceAll({
    required List<FolderObject> folders,
    required List<TagObject> tags,
    required List<NoteAudioObject> audio,
    required List<NoteObject> notes,
    required List<NoteTranscriptionSegmentObject> segments,
  }) async {
    await _db.runInTransactionAsync<void, Object?>((Store store, Object? _) {
      final box = store.box;

      box<NoteTranscriptionSegmentObject>().removeAll();
      box<NoteAudioObject>().removeAll();
      box<NoteObject>().removeAll();
      box<FolderObject>().removeAll();
      box<TagObject>().removeAll();

      if (folders.isNotEmpty) {
        box<FolderObject>().putMany(folders, mode: PutMode.insert);
      }
      if (tags.isNotEmpty) {
        box<TagObject>().putMany(tags, mode: PutMode.insert);
      }
      if (audio.isNotEmpty) {
        box<NoteAudioObject>().putMany(audio, mode: PutMode.insert);
      }
      if (notes.isNotEmpty) {
        box<NoteObject>().putMany(notes, mode: PutMode.insert);
      }
      if (segments.isNotEmpty) {
        box<NoteTranscriptionSegmentObject>().putMany(
          segments,
          mode: PutMode.insert,
        );
      }
    }, param: null);
  }
}
