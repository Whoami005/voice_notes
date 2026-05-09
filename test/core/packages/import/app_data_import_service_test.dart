import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/error/app_exception.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/core/packages/backup/app_data_backup_codec.dart';
import 'package:voice_notes/core/packages/backup/app_data_backup_models.dart';
import 'package:voice_notes/core/packages/import/app_data_import_models.dart';
import 'package:voice_notes/core/packages/import/app_data_import_service.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/data/local/data_sources/app_data_restore_local_data_source.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/data/local/models/note_transcription_segment_object.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_origin_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';
import 'package:voice_notes/feature/domain/enums/transcription_task_type.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/domain/repositories/tag_repository.dart';

class MockFolderRepository extends Mock implements FolderRepository {}

class MockTagRepository extends Mock implements TagRepository {}

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory documentsDir;
  late SharedPreferences prefs;
  late RecordingPreferences recordingPreferences;
  late MockFolderRepository folderRepository;
  late MockTagRepository tagRepository;
  late MockNoteRepository noteRepository;
  late _FakeTranscriptionQueueController queueController;
  late _FakeAudioPlaybackController audioPlaybackController;
  late _CapturingRestoreLocalDataSource restoreLocalDataSource;

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
              return documentsDir.path;
            case 'getTemporaryDirectory':
              return tempDir.path;
            default:
              return null;
          }
        });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      ThemeCubit.prefsKey: 'dark',
      LocaleCubit.prefsKey: 'ru',
      'recording.keep_originals': true,
    });
    prefs = await SharedPreferences.getInstance();
    recordingPreferences = RecordingPreferences(prefs);

    folderRepository = MockFolderRepository();
    tagRepository = MockTagRepository();
    noteRepository = MockNoteRepository();
    queueController = _FakeTranscriptionQueueController();
    audioPlaybackController = _FakeAudioPlaybackController();
    restoreLocalDataSource = _CapturingRestoreLocalDataSource();

    tempDir = await Directory.systemTemp.createTemp('voice-notes-import-temp');
    documentsDir = await Directory.systemTemp.createTemp(
      'voice-notes-import-docs',
    );

    when(() => folderRepository.getAll()).thenAnswer((_) async => const []);
    when(() => tagRepository.getAll()).thenAnswer((_) async => const []);
    when(() => noteRepository.getAll()).thenAnswer((_) async => const []);
  });

  tearDown(() async {
    await queueController.dispose();

    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
    if (documentsDir.existsSync()) {
      await documentsDir.delete(recursive: true);
    }
  });

  AppDataImportService createService() {
    return AppDataImportServiceImpl(
      folderRepository: folderRepository,
      tagRepository: tagRepository,
      noteRepository: noteRepository,
      recordingPreferences: recordingPreferences,
      sharedPreferences: prefs,
      queueController: queueController,
      audioPlaybackController: audioPlaybackController,
      restoreLocalDataSource: restoreLocalDataSource,
    );
  }

  group('AppDataImportService', () {
    test(
      'inspectBackup reports preview warnings for missing audio files',
      () async {
        final fixture = _buildBackupFixture(includeAudioBinary: false);
        final backupFile = await _writeBackupArchive(
          fixture: fixture,
          directory: tempDir,
        );

        final preview = await createService().inspectBackup(backupFile);

        expect(preview.fileName, 'backup.zip');
        expect(preview.notesCount, fixture.backup.notes.length);
        expect(preview.includesAudio, isTrue);
        expect(preview.warningsCount, 1);
      },
    );

    test('imports backup, restores data, audio, and settings', () async {
      final fixture = _buildBackupFixture();
      final backupFile = await _writeBackupArchive(
        fixture: fixture,
        directory: tempDir,
      );

      final result = await createService().importBackup(file: backupFile);

      expect(result.hasWarnings, isFalse);
      expect(result.restoredFoldersCount, 1);
      expect(result.restoredTagsCount, 1);
      expect(result.restoredNotesCount, 2);
      expect(result.restoredAudioCount, 1);

      expect(restoreLocalDataSource.calls, hasLength(1));
      final call = restoreLocalDataSource.calls.single;
      expect(call.folders, hasLength(1));
      expect(call.tags, hasLength(1));
      expect(call.audio, hasLength(1));
      expect(call.notes, hasLength(2));
      expect(call.segments, hasLength(1));

      final folder = call.folders.single;
      expect(folder.uid, 'folder-1');
      expect(folder.name, 'Inbox');
      expect(folder.description, 'Primary folder');

      final tag = call.tags.single;
      expect(tag.name, 'meeting');

      final audio = call.audio.single;
      expect(audio.relativePath, fixture.audioRelativePath);
      expect(audio.folderUid, 'folder-1');
      expect(audio.sizeBytes, fixture.audioBytes.length);

      final importedNote = call.notes.firstWhere(
        (note) => note.uid == 'audio-1',
      );
      expect(importedNote.statusValue, TranscriptionStatus.queued.value);
      expect(importedNote.folder.target?.uid, 'folder-1');
      expect(
        importedNote.audio.target?.relativePath,
        fixture.audioRelativePath,
      );
      expect(importedNote.tags.map((item) => item.name), contains('meeting'));
      expect(importedNote.transcriptionModelId, 'whisper-small');
      expect(
        importedNote.transcriptionTaskTypeValue,
        TranscriptionTaskType.transcribe.value,
      );
      expect(
        importedNote.transcriptionStrategyValue,
        AsrTranscriptionStrategy.chunkedVad.value,
      );

      final manualNote = call.notes.firstWhere(
        (note) => note.uid == 'manual-1',
      );
      expect(manualNote.audio.target, isNull);
      expect(manualNote.folder.target, isNull);

      final segment = call.segments.single;
      expect(segment.text, 'Discuss import');
      expect(segment.note.target?.uid, 'audio-1');

      final importedAudioFile = File(
        p.join(documentsDir.path, fixture.audioRelativePath),
      );
      expect(importedAudioFile.existsSync(), isTrue);
      expect(await importedAudioFile.readAsBytes(), fixture.audioBytes);

      expect(audioPlaybackController.clearSessionCalls, 1);
      expect(prefs.getString(ThemeCubit.prefsKey), 'dark');
      expect(prefs.getString(LocaleCubit.prefsKey), 'ru');
      expect(recordingPreferences.keepOriginals, isTrue);
    });

    test(
      'imports notes without audio relation when archive misses binary',
      () async {
        final fixture = _buildBackupFixture(includeAudioBinary: false);
        final backupFile = await _writeBackupArchive(
          fixture: fixture,
          directory: tempDir,
        );

        final result = await createService().importBackup(file: backupFile);

        expect(result.hasWarnings, isTrue);
        expect(
          result.warnings,
          contains(const MissingAudioImportWarning(count: 1)),
        );

        expect(restoreLocalDataSource.calls, hasLength(1));
        final call = restoreLocalDataSource.calls.single;
        expect(call.audio, isEmpty);

        final importedNote = call.notes.firstWhere(
          (note) => note.uid == 'audio-1',
        );
        expect(importedNote.audio.target, isNull);
        expect(call.segments.single.note.target?.uid, 'audio-1');

        final importedAudioFile = File(
          p.join(documentsDir.path, fixture.audioRelativePath),
        );
        expect(importedAudioFile.existsSync(), isFalse);
        expect(audioPlaybackController.clearSessionCalls, 1);
      },
    );

    test(
      'blocks queued and processing queue states before mutating data',
      () async {
        final fixture = _buildBackupFixture();
        final backupFile = await _writeBackupArchive(
          fixture: fixture,
          directory: tempDir,
        );

        for (final snapshot in <TranscriptionQueueSnapshot>[
          const TranscriptionQueueSnapshot(queued: ['queued-note']),
          const TranscriptionQueueSnapshot(processing: 'processing-note'),
        ]) {
          queueController.currentSnapshot = snapshot;

          await expectLater(
            createService().importBackup(file: backupFile),
            throwsA(isA<CustomException>()),
          );

          expect(restoreLocalDataSource.calls, isEmpty);
          expect(audioPlaybackController.clearSessionCalls, 0);
          expect(prefs.getString(ThemeCubit.prefsKey), 'dark');
          expect(prefs.getString(LocaleCubit.prefsKey), 'ru');
          expect(recordingPreferences.keepOriginals, isTrue);
        }
      },
    );

    test(
      'restores previous snapshot and recordings when restore fails',
      () async {
        final fixture = _buildBackupFixture();
        final backupFile = await _writeBackupArchive(
          fixture: fixture,
          directory: tempDir,
        );
        restoreLocalDataSource.throwOnCall = 1;

        when(
          () => folderRepository.getAll(),
        ).thenAnswer((_) async => [_currentFolder()]);
        when(
          () => tagRepository.getAll(),
        ).thenAnswer((_) async => [_currentTag()]);
        when(
          () => noteRepository.getAll(),
        ).thenAnswer((_) async => [_currentManualNote()]);

        final existingRecording = File(
          p.join(documentsDir.path, 'audio/recordings/existing.wav'),
        );
        await existingRecording.parent.create(recursive: true);
        await existingRecording.writeAsBytes(const [9, 8, 7, 6]);

        await expectLater(
          createService().importBackup(file: backupFile),
          throwsA(isA<StateError>()),
        );

        expect(restoreLocalDataSource.calls, hasLength(2));
        final rollbackCall = restoreLocalDataSource.calls.last;
        expect(rollbackCall.folders.single.uid, 'current-folder');
        expect(rollbackCall.tags.single.name, 'current-tag');
        expect(rollbackCall.notes.single.uid, 'current-note');

        expect(existingRecording.existsSync(), isTrue);
        expect(await existingRecording.readAsBytes(), const [9, 8, 7, 6]);

        final importedAudioFile = File(
          p.join(documentsDir.path, fixture.audioRelativePath),
        );
        expect(importedAudioFile.existsSync(), isFalse);

        expect(audioPlaybackController.clearSessionCalls, 1);
        expect(prefs.getString(ThemeCubit.prefsKey), 'dark');
        expect(prefs.getString(LocaleCubit.prefsKey), 'ru');
        expect(recordingPreferences.keepOriginals, isTrue);
      },
    );
  });
}

_BackupFixture _buildBackupFixture({bool includeAudioBinary = true}) {
  const audioRelativePath = 'audio/recordings/audio-1.wav';
  const audioBytes = <int>[1, 2, 3, 4];

  const backup = AppDataBackupPayload(
    settings: AppDataBackupSettings(
      themeMode: 'light',
      localeCode: 'en',
      recording: AppDataBackupRecordingSettings(keepOriginals: false),
      selectedModelId: 'streaming-zipformer-en-2023-06-26',
    ),
    folders: [
      AppDataBackupFolder(
        uid: 'folder-1',
        name: 'Inbox',
        description: 'Primary folder',
        colorArgb: 0xFF336699,
        iconRef: 'material:book',
        createdAt: '2026-05-01T08:00:00.000Z',
        updatedAt: '2026-05-07T09:00:00.000Z',
      ),
    ],
    tags: [
      AppDataBackupTag(
        name: 'Meeting',
        colorArgb: 0xFF009688,
        createdAt: '2026-05-02T10:00:00.000Z',
      ),
    ],
    notes: [
      AppDataBackupNote(
        uuid: 'audio-1',
        folderId: 'folder-1',
        text: 'Discuss import plan',
        tagNames: ['Meeting'],
        status: 'transcribing',
        failureReason: null,
        createdAt: '2026-05-08T10:55:00.000Z',
        updatedAt: '2026-05-08T11:05:00.000Z',
        origin: AppDataBackupAudioOrigin(
          sourceDurationMs: 42000,
          audio: AppDataBackupAudioFile(
            relativePath: audioRelativePath,
            sizeBytes: 4,
            sampleRate: 16000,
            durationMs: 5000,
            fileIncluded: true,
          ),
          transcription: AppDataBackupTranscription(
            modelId: 'whisper-small',
            languageCode: 'ru',
            taskType: 'transcribe',
            transcribedAt: '2026-05-08T11:00:00.000Z',
            processingTimeMs: 8000,
            strategyUsed: 'chunkedVad',
            usedVad: true,
            fellBackFromVad: false,
            emotionLabel: 'calm',
            eventLabel: 'meeting',
            usedItn: true,
            usedPunctuation: true,
          ),
          transcriptionSegments: [
            AppDataBackupTranscriptionSegment(
              index: 0,
              text: 'Discuss import',
              startMs: 0,
              endMs: 1200,
              languageCode: 'ru',
              tokens: ['Discuss', 'import'],
              tokenTimestampsMs: [0, 600],
            ),
          ],
        ),
      ),
      AppDataBackupNote(
        uuid: 'manual-1',
        folderId: null,
        text: 'Manual backup note',
        tagNames: [],
        status: 'cancelled',
        failureReason: null,
        createdAt: '2026-05-08T09:30:00.000Z',
        updatedAt: '2026-05-08T09:31:00.000Z',
        origin: AppDataBackupManualOrigin(),
      ),
    ],
  );

  return _BackupFixture(
    backup: backup,
    audioRelativePath: audioRelativePath,
    audioBytes: audioBytes,
    audioFiles: includeAudioBinary ? {audioRelativePath: audioBytes} : const {},
  );
}

Future<XFile> _writeBackupArchive({
  required _BackupFixture fixture,
  required Directory directory,
}) async {
  final archive = Archive();
  final manifest = AppDataBackupManifest(
    schemaVersion: 1,
    app: 'voice_notes',
    exportedAt: '2026-05-08T12:30:45.000Z',
    includesAudio: true,
    counts: AppDataBackupCounts(
      folders: fixture.backup.folders.length,
      tags: fixture.backup.tags.length,
      notes: fixture.backup.notes.length,
      audioFiles: 1,
    ),
  );

  archive
    ..addFile(
      ArchiveFile.string(
        AppDataBackupCodec.manifestFileName,
        AppDataBackupCodec.encodeJson(manifest.toJson()),
      ),
    )
    ..addFile(
      ArchiveFile.string(
        AppDataBackupCodec.backupFileName,
        AppDataBackupCodec.encodeJson(fixture.backup.toJson()),
      ),
    );

  for (final entry in fixture.audioFiles.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }

  final bytes = ZipEncoder().encode(archive);

  final file = File(p.join(directory.path, 'backup.zip'));
  await file.writeAsBytes(bytes, flush: true);

  return XFile(file.path);
}

FolderEntity _currentFolder() {
  return FolderEntity(
    uid: 'current-folder',
    name: 'Current',
    color: const Color(0xFF123456),
    icon: MaterialIconRefEntity.folder,
    notesCount: 1,
    createdAt: DateTime.utc(2026, 4, 1, 8),
    updatedAt: DateTime.utc(2026, 4, 2, 9),
    description: 'Current data',
  );
}

TagEntity _currentTag() {
  return TagEntity(
    name: 'current-tag',
    color: const Color(0xFFAA5500),
    createdAt: DateTime.utc(2026, 4, 2, 10),
  );
}

NoteEntity _currentManualNote() {
  return NoteEntity(
    uuid: 'current-note',
    folderId: 'current-folder',
    text: 'Current manual note',
    origin: const ManualNoteOriginEntity(),
    tags: [_currentTag()],
    status: TranscriptionStatus.completed,
    createdAt: DateTime.utc(2026, 4, 3, 10),
    updatedAt: DateTime.utc(2026, 4, 3, 11),
  );
}

class _BackupFixture {
  final AppDataBackupPayload backup;
  final String audioRelativePath;
  final List<int> audioBytes;
  final Map<String, List<int>> audioFiles;

  const _BackupFixture({
    required this.backup,
    required this.audioRelativePath,
    required this.audioBytes,
    required this.audioFiles,
  });
}

class _CapturedRestoreCall {
  final List<FolderObject> folders;
  final List<TagObject> tags;
  final List<NoteAudioObject> audio;
  final List<NoteObject> notes;
  final List<NoteTranscriptionSegmentObject> segments;

  const _CapturedRestoreCall({
    required this.folders,
    required this.tags,
    required this.audio,
    required this.notes,
    required this.segments,
  });
}

class _CapturingRestoreLocalDataSource
    implements AppDataRestoreLocalDataSource {
  final List<_CapturedRestoreCall> calls = [];

  int? throwOnCall;

  @override
  Future<void> replaceAll({
    required List<FolderObject> folders,
    required List<TagObject> tags,
    required List<NoteAudioObject> audio,
    required List<NoteObject> notes,
    required List<NoteTranscriptionSegmentObject> segments,
  }) async {
    calls.add(
      _CapturedRestoreCall(
        folders: List<FolderObject>.of(folders),
        tags: List<TagObject>.of(tags),
        audio: List<NoteAudioObject>.of(audio),
        notes: List<NoteObject>.of(notes),
        segments: List<NoteTranscriptionSegmentObject>.of(segments),
      ),
    );

    if (throwOnCall != null && calls.length == throwOnCall) {
      throw StateError('restore failed');
    }
  }
}

class _FakeTranscriptionQueueController
    implements TranscriptionQueueController {
  final StreamController<TranscriptionQueueSnapshot> _snapshotController =
      StreamController<TranscriptionQueueSnapshot>.broadcast();

  TranscriptionQueueSnapshot currentSnapshot =
      const TranscriptionQueueSnapshot();

  @override
  Stream<TranscriptionQueueSnapshot> get snapshots =>
      _snapshotController.stream;

  @override
  TranscriptionQueueSnapshot get current => currentSnapshot;

  @override
  Future<AsrResult> transcribePriorityFile(
    String filePath, {
    required Duration audioDurationHint,
    void Function()? onStarted,
  }) async {
    return const AsrResult(text: 'ok');
  }

  @override
  Future<void> dispose() async {
    await _snapshotController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Fake TranscriptionQueueController: ${invocation.memberName} not stubbed',
  );
}

class _FakeAudioPlaybackController implements AudioPlaybackController {
  int clearSessionCalls = 0;

  @override
  PlaybackSessionState get session => const PlaybackSessionState.hidden();

  @override
  Stream<PlaybackSessionState> get sessionStream =>
      const Stream<PlaybackSessionState>.empty();

  @override
  Future<void> clearSession() async {
    clearSessionCalls += 1;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<List<double>?> getWaveform(String trackId) async => null;

  @override
  Future<void> pause() async {}

  @override
  Future<void> play(String trackId) async {}

  @override
  void register(String trackId, CachedTrackState state) {}

  @override
  Future<void> seek(String trackId, Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Stream<TrackState> trackStateStream(String trackId) =>
      const Stream<TrackState>.empty();

  @override
  Future<void> togglePlayPause(String trackId) async {}
}
