import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/core/packages/export/app_data_export_models.dart';
import 'package:voice_notes/core/packages/export/app_data_export_service.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_origin_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_meta_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_segment_entity.dart';
import 'package:voice_notes/feature/domain/entities/storage_overview_stats.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';
import 'package:voice_notes/feature/domain/enums/transcription_task_type.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';
import 'package:voice_notes/feature/domain/repositories/tag_repository.dart';

class MockFolderRepository extends Mock implements FolderRepository {}

class MockTagRepository extends Mock implements TagRepository {}

class MockNoteRepository extends Mock implements NoteRepository {}

class MockStorageStatsRepository extends Mock
    implements StorageStatsRepository {}

class MockModelRepository extends Mock implements ModelRepository {}

void main() {
  late MockFolderRepository folderRepository;
  late MockTagRepository tagRepository;
  late MockNoteRepository noteRepository;
  late MockStorageStatsRepository storageStatsRepository;
  late MockModelRepository modelRepository;
  late SharedPreferences prefs;
  late RecordingPreferences recordingPreferences;
  late Directory tempDir;
  late Directory documentsDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_theme': 'dark',
      'app_locale': 'ru',
      'recording.keep_originals': true,
    });
    prefs = await SharedPreferences.getInstance();
    recordingPreferences = RecordingPreferences(prefs);

    folderRepository = MockFolderRepository();
    tagRepository = MockTagRepository();
    noteRepository = MockNoteRepository();
    storageStatsRepository = MockStorageStatsRepository();
    modelRepository = MockModelRepository();

    tempDir = await Directory.systemTemp.createTemp('voice-notes-export-test');
    documentsDir = Directory(p.join(tempDir.path, 'documents'));
    await documentsDir.create(recursive: true);

    when(() => folderRepository.getAll()).thenAnswer((_) async => const []);
    when(() => tagRepository.getAll()).thenAnswer((_) async => const []);
    when(() => noteRepository.getAll()).thenAnswer((_) async => const []);
    when(
      () => storageStatsRepository.getOverview(),
    ).thenAnswer((_) async => const StorageOverviewStats.empty());
    when(
      () => modelRepository.getSelectedModel(),
    ).thenAnswer((_) async => null);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  AppDataExportService createService() {
    return AppDataExportServiceImpl.test(
      folderRepository: folderRepository,
      tagRepository: tagRepository,
      noteRepository: noteRepository,
      storageStatsRepository: storageStatsRepository,
      modelRepository: modelRepository,
      recordingPreferences: recordingPreferences,
      sharedPreferences: prefs,
      now: () => DateTime.utc(2026, 5, 8, 12, 30, 45),
      tempDirectoryProvider: () async => tempDir,
      audioPathResolver: (relativePath) async =>
          p.join(documentsDir.path, relativePath),
    );
  }

  Future<Archive> exportArchive(AppDataExportOptions options) async {
    final artifact = await createService().createBackup(options: options);
    final bytes = await artifact.file.readAsBytes();
    return ZipDecoder().decodeBytes(bytes);
  }

  String archiveText(Archive archive, String name) {
    final file = archive.files.firstWhere((entry) => entry.name == name);
    return utf8.decode(file.content as List<int>);
  }

  Future<File> writeAudioFixture(String relativePath, List<int> bytes) async {
    final file = File(p.join(documentsDir.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file;
  }

  FolderEntity buildFolder() {
    return FolderEntity(
      uid: 'folder-1',
      name: 'Inbox',
      color: const Color(0xFF336699),
      icon: MaterialIconRefEntity.book,
      notesCount: 1,
      createdAt: DateTime.utc(2026, 5, 1, 8),
      updatedAt: DateTime.utc(2026, 5, 7, 9),
      description: 'Primary folder',
    );
  }

  TagEntity buildTag() {
    return TagEntity(
      name: 'meeting',
      color: const Color(0xFF009688),
      createdAt: DateTime.utc(2026, 5, 2, 10),
    );
  }

  NoteEntity buildAudioNote({
    required NoteAudioEntity? audio,
    required TranscriptionStatus status,
    required TranscriptionFailureReason? failureReason,
    String? folderId = 'folder-1',
  }) {
    return NoteEntity(
      uuid: 'note-audio-1',
      folderId: folderId,
      text: 'Discuss export plan',
      origin: AudioNoteOriginEntity(
        sourceDuration: const Duration(seconds: 42),
        audio: audio,
        transcription: NoteTranscriptionMetaEntity(
          modelId: AsrModelIdEnum.whisperSmall,
          languageCode: 'ru',
          taskType: TranscriptionTaskType.transcribe,
          transcribedAt: DateTime.utc(2026, 5, 8, 11),
          processingTime: const Duration(seconds: 8),
          strategyUsed: AsrTranscriptionStrategy.chunkedVad,
          usedVad: true,
          fellBackFromVad: false,
          emotionLabel: 'calm',
          eventLabel: 'meeting',
          usedItn: true,
          usedPunctuation: true,
        ),
        transcriptionSegments: const [
          NoteTranscriptionSegmentEntity(
            index: 0,
            text: 'Discuss',
            start: Duration.zero,
            end: Duration(seconds: 1),
            languageCode: 'ru',
          ),
          NoteTranscriptionSegmentEntity(
            index: 1,
            text: 'export plan',
            start: Duration(seconds: 1),
            end: Duration(seconds: 3),
            languageCode: 'ru',
          ),
        ],
      ),
      tags: [buildTag()],
      status: status,
      failureReason: failureReason,
      createdAt: DateTime.utc(2026, 5, 8, 10, 55),
      updatedAt: DateTime.utc(2026, 5, 8, 11, 5),
    );
  }

  NoteEntity buildManualNote() {
    return NoteEntity(
      uuid: 'note-manual-1',
      text: 'Plain manual note',
      origin: const ManualNoteOriginEntity(),
      status: TranscriptionStatus.cancelled,
      createdAt: DateTime.utc(2026, 5, 8, 9, 30),
      updatedAt: DateTime.utc(2026, 5, 8, 9, 31),
    );
  }

  group('AppDataExportService', () {
    test(
      'creates zip archive with manifest, backup, and audio files',
      () async {
        const audio = NoteAudioEntity(
          relativePath: 'audio/recordings/note-audio-1.wav',
          sizeBytes: 4,
          sampleRate: 16000,
          duration: Duration(seconds: 5),
        );
        await writeAudioFixture(audio.relativePath, const [1, 2, 3, 4]);

        when(
          () => folderRepository.getAll(),
        ).thenAnswer((_) async => [buildFolder()]);
        when(
          () => tagRepository.getAll(),
        ).thenAnswer((_) async => [buildTag()]);
        when(() => noteRepository.getAll()).thenAnswer(
          (_) async => [
            buildAudioNote(
              audio: audio,
              status: TranscriptionStatus.failed,
              failureReason: TranscriptionFailureReason.transcriptionTimedOut,
            ),
            buildManualNote(),
          ],
        );
        when(() => modelRepository.getSelectedModel()).thenAnswer(
          (_) async => AsrModelEntity.availableModels.first.copyWith(
            isDownloaded: true,
            isSelected: true,
          ),
        );

        final archive = await exportArchive(
          const AppDataExportOptions(includeAudio: true),
        );

        expect(
          archive.files.map((file) => file.name),
          containsAll([
            'manifest.json',
            'backup.json',
            'audio/recordings/note-audio-1.wav',
          ]),
        );
        expect(
          archive.files.any((file) => file.name.contains('voice-notes-box_db')),
          isFalse,
        );
        expect(
          archive.files.any((file) => file.name.contains('asr_models')),
          isFalse,
        );

        final manifest =
            json.decode(archiveText(archive, 'manifest.json'))
                as Map<String, dynamic>;
        final backup =
            json.decode(archiveText(archive, 'backup.json'))
                as Map<String, dynamic>;

        expect(manifest['schemaVersion'], 1);
        expect(manifest['includesAudio'], isTrue);
        expect(manifest['counts']['folders'], 1);
        expect(manifest['counts']['tags'], 1);
        expect(manifest['counts']['notes'], 2);
        expect(manifest['counts']['audioFiles'], 1);

        expect(backup['settings']['themeMode'], 'dark');
        expect(backup['settings']['localeCode'], 'ru');
        expect(backup['settings']['recording']['keepOriginals'], isTrue);
        expect(
          backup['settings']['selectedModelId'],
          AsrModelEntity.availableModels.first.uuid.value,
        );

        final exportedAudioNote = (backup['notes'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .firstWhere((note) => note['uuid'] == 'note-audio-1');
        expect(exportedAudioNote['status'], 'failed');
        expect(exportedAudioNote['failureReason'], 'transcriptionTimedOut');
        expect(exportedAudioNote['folderId'], 'folder-1');
        expect(exportedAudioNote['tagNames'], ['meeting']);
        expect(exportedAudioNote['origin']['type'], 'audio');
        expect(exportedAudioNote['origin']['audio']['fileIncluded'], isTrue);
        expect(
          exportedAudioNote['origin']['audio']['relativePath'],
          'audio/recordings/note-audio-1.wav',
        );
      },
    );

    test('omits audio binaries while preserving audio metadata', () async {
      const audio = NoteAudioEntity(
        relativePath: 'audio/recordings/note-audio-1.wav',
        sizeBytes: 6,
        sampleRate: 16000,
        duration: Duration(seconds: 7),
      );
      await writeAudioFixture(audio.relativePath, const [4, 5, 6, 7, 8, 9]);

      when(() => noteRepository.getAll()).thenAnswer(
        (_) async => [
          buildAudioNote(
            audio: audio,
            status: TranscriptionStatus.completed,
            failureReason: null,
            folderId: null,
          ),
        ],
      );

      final archive = await exportArchive(const AppDataExportOptions());

      expect(
        archive.files.any((file) => file.name.startsWith('audio/recordings/')),
        isFalse,
      );

      final manifest =
          json.decode(archiveText(archive, 'manifest.json'))
              as Map<String, dynamic>;
      final backup =
          json.decode(archiveText(archive, 'backup.json'))
              as Map<String, dynamic>;
      final note =
          (backup['notes'] as List<dynamic>).single as Map<String, dynamic>;

      expect(manifest['includesAudio'], isFalse);
      expect(manifest['counts']['audioFiles'], 0);
      expect(note['folderId'], isNull);
      expect(note['origin']['audio']['fileIncluded'], isFalse);
      expect(note['origin']['audio']['sizeBytes'], 6);
      expect(note['origin']['audio']['durationMs'], 7000);
    });

    test('builds empty backup and summary without selected model', () async {
      final service = createService();
      when(() => storageStatsRepository.getOverview()).thenAnswer(
        (_) async => const StorageOverviewStats(totalBytes: 0, totalCount: 0),
      );

      final summary = await service.getSummary();
      final archive = await exportArchive(const AppDataExportOptions());
      final backup =
          json.decode(archiveText(archive, 'backup.json'))
              as Map<String, dynamic>;

      expect(
        summary,
        const AppDataExportSummary(notesCount: 0, audioCount: 0, audioBytes: 0),
      );
      expect(backup['settings']['selectedModelId'], isNull);
      expect(backup['folders'], isEmpty);
      expect(backup['tags'], isEmpty);
      expect(backup['notes'], isEmpty);
    });
  });
}
