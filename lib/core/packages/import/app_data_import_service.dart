import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cross_file/cross_file.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/error/app_exception.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/backup/app_data_backup_codec.dart';
import 'package:voice_notes/core/packages/backup/app_data_backup_models.dart';
import 'package:voice_notes/core/packages/import/app_data_import_models.dart';
import 'package:voice_notes/core/packages/path/app_path_provider.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/data/local/data_sources/app_data_restore_local_data_source.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/data/local/models/note_audio_object.dart';
import 'package:voice_notes/feature/data/local/models/note_object.dart';
import 'package:voice_notes/feature/data/local/models/note_transcription_segment_object.dart';
import 'package:voice_notes/feature/data/local/models/tag_object.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_origin_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/domain/repositories/tag_repository.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

abstract interface class AppDataImportService {
  Future<AppDataImportPreview> inspectBackup(XFile file);

  Future<AppDataImportResult> importBackup({required XFile file});
}

@Singleton(as: AppDataImportService)
class AppDataImportServiceImpl implements AppDataImportService {
  static const _expectedApp = 'voice_notes';
  static const _expectedSchemaVersion = 1;

  final FolderRepository _folderRepository;
  final TagRepository _tagRepository;
  final NoteRepository _noteRepository;
  final RecordingPreferences _recordingPreferences;
  final SharedPreferences _sharedPreferences;
  final TranscriptionQueueController _queueController;
  final AudioPlaybackController _audioPlaybackController;
  final AppDataRestoreLocalDataSource _restoreLocalDataSource;

  AppDataImportServiceImpl({
    required FolderRepository folderRepository,
    required TagRepository tagRepository,
    required NoteRepository noteRepository,
    required RecordingPreferences recordingPreferences,
    required SharedPreferences sharedPreferences,
    required TranscriptionQueueController queueController,
    required AudioPlaybackController audioPlaybackController,
    required AppDataRestoreLocalDataSource restoreLocalDataSource,
  }) : _folderRepository = folderRepository,
       _tagRepository = tagRepository,
       _noteRepository = noteRepository,
       _recordingPreferences = recordingPreferences,
       _sharedPreferences = sharedPreferences,
       _queueController = queueController,
       _audioPlaybackController = audioPlaybackController,
       _restoreLocalDataSource = restoreLocalDataSource;

  @override
  Future<AppDataImportPreview> inspectBackup(XFile file) async {
    final bundle = await _readBundle(file);
    final warnings = _previewWarnings(bundle.archive, bundle.backup);

    return AppDataImportPreview(
      fileName: file.name,
      manifest: bundle.manifest,
      warningsCount: warnings.length,
    );
  }

  @override
  Future<AppDataImportResult> importBackup({required XFile file}) async {
    final bundle = await _readBundle(file);
    _validateBundle(bundle);
    _guardQueueIdle();

    final tempRoot = await AppPathProvider.getTemporaryDirectory();
    final sessionDir = Directory(
      p.join(
        tempRoot.path,
        'voice_notes_import_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await sessionDir.create(recursive: true);

    final importedRecordingsDir = Directory(
      p.join(sessionDir.path, 'imported_recordings'),
    );
    final rollbackRecordingsDir = Directory(
      p.join(sessionDir.path, 'rollback_recordings'),
    );
    await importedRecordingsDir.create(recursive: true);
    await rollbackRecordingsDir.create(recursive: true);

    final warnings = <AppDataImportWarning>[];

    try {
      final availableAudio = await _stageAudioFiles(
        archive: bundle.archive,
        backup: bundle.backup,
        destinationRoot: importedRecordingsDir,
        warnings: warnings,
      );

      final currentSnapshot = await _buildCurrentSnapshot();

      _guardQueueIdle();
      await _audioPlaybackController.clearSession();

      final recordingsPath = await AudioPaths.recordingsDir;
      final recordingsDir = Directory(recordingsPath);
      if (recordingsDir.existsSync()) {
        await recordingsDir.rename(rollbackRecordingsDir.path);
      }

      try {
        final restoreGraph = _buildRestoreGraph(
          backup: bundle.backup,
          availableAudioPaths: availableAudio,
        );

        await _restoreLocalDataSource.replaceAll(
          folders: restoreGraph.folders,
          tags: restoreGraph.tags,
          audio: restoreGraph.audio,
          notes: restoreGraph.notes,
          segments: restoreGraph.segments,
        );

        await _swapImportedRecordings(
          sourceDir: importedRecordingsDir,
          targetPath: recordingsPath,
        );
      } catch (error, stackTrace) {
        await _restoreRollbackSnapshot(
          snapshot: currentSnapshot,
          rollbackRecordingsDir: rollbackRecordingsDir,
          recordingsPath: recordingsPath,
          importedRecordingsDir: importedRecordingsDir,
        );
        Error.throwWithStackTrace(error, stackTrace);
      }

      return AppDataImportResult(
        backup: bundle.backup,
        warnings: warnings,
        restoredFoldersCount: bundle.backup.folders.length,
        restoredTagsCount: bundle.backup.tags.length,
        restoredNotesCount: bundle.backup.notes.length,
        restoredAudioCount: availableAudio.length,
      );
    } finally {
      await _cleanupSession(sessionDir);
    }
  }

  Future<_BackupBundle> _readBundle(XFile file) async {
    final bundle = await Isolate.run(() => _readBundleFromPath(file.path));

    _validateBundle(bundle);

    return bundle;
  }

  void _validateBundle(_BackupBundle bundle) {
    final manifest = bundle.manifest;
    if (manifest.app != _expectedApp) {
      throw CustomException('Неподдерживаемый backup: ${manifest.app}');
    }
    if (manifest.schemaVersion != _expectedSchemaVersion) {
      throw CustomException(
        'Неподдерживаемая версия backup: ${manifest.schemaVersion}',
      );
    }
    if (bundle.backup.folders.length != manifest.counts.folders ||
        bundle.backup.tags.length != manifest.counts.tags ||
        bundle.backup.notes.length != manifest.counts.notes) {
      throw const FormatException.json('Backup counts mismatch');
    }
  }

  List<AppDataImportWarning> _previewWarnings(
    Archive archive,
    AppDataBackupPayload backup,
  ) {
    final warnings = <AppDataImportWarning>[];
    final archiveNames = archive.files.map((file) => file.name).toSet();
    final missingAudio = _countMissingAudio(archiveNames, backup);
    if (missingAudio > 0) {
      warnings.add(MissingAudioImportWarning(count: missingAudio));
    }

    return warnings;
  }

  void _guardQueueIdle() {
    final current = _queueController.current;
    final hasQueued = current.queued.isNotEmpty;
    final hasProcessing = current.processing != null;
    if (hasQueued || hasProcessing) {
      throw const CustomException(
        'Импорт недоступен, пока очередь транскрибации не пуста',
      );
    }
  }

  Future<List<String>> _stageAudioFiles({
    required Archive archive,
    required AppDataBackupPayload backup,
    required Directory destinationRoot,
    required List<AppDataImportWarning> warnings,
  }) async {
    final availablePaths = <String>[];
    final archiveByName = {for (final file in archive.files) file.name: file};
    int missingAudio = 0;

    for (final note in backup.notes) {
      final origin = note.origin.asAudio;
      final audio = origin?.audio;
      if (origin == null || audio == null || !audio.fileIncluded) continue;

      final archiveFile = archiveByName[audio.relativePath];
      final Uint8List? content = archiveFile?.content;
      if (content == null || content.isEmpty) {
        missingAudio += 1;
        continue;
      }

      final outFile = File(
        p.join(destinationRoot.path, _recordingsImportPath(audio.relativePath)),
      );
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(content, flush: true);
      availablePaths.add(audio.relativePath);
    }

    if (missingAudio > 0) {
      warnings.add(MissingAudioImportWarning(count: missingAudio));
    }

    return availablePaths;
  }

  _RestoreGraph _buildRestoreGraph({
    required AppDataBackupPayload backup,
    required List<String> availableAudioPaths,
  }) {
    final folderObjectsByUid = <String, FolderObject>{
      for (final folder in backup.folders) folder.uid: folder.toObject(),
    };
    final tagObjectsByName = <String, TagObject>{
      for (final tag in backup.tags)
        tag.name.toLowerCase().trim(): tag.toObject(),
    };

    final folders = folderObjectsByUid.values.toList();
    final tags = tagObjectsByName.values.toList();

    final audio = <NoteAudioObject>[];
    final notes = <NoteObject>[];
    final segments = <NoteTranscriptionSegmentObject>[];

    for (final backupNote in backup.notes) {
      final folderObject = backupNote.folderId == null
          ? null
          : folderObjectsByUid[backupNote.folderId!];

      final noteTagObjects = backupNote.tagNames
          .map((name) => tagObjectsByName[name.toLowerCase().trim()])
          .whereType<TagObject>()
          .toList();

      final origin = backupNote.origin.asAudio;
      final audioBackup = origin?.audio;
      final hasAudio =
          origin != null &&
          audioBackup != null &&
          audioBackup.fileIncluded &&
          availableAudioPaths.contains(audioBackup.relativePath);

      NoteAudioObject? noteAudioObject;
      if (hasAudio) {
        noteAudioObject = audioBackup.toObject(folderUid: backupNote.folderId);
        if (noteAudioObject != null) audio.add(noteAudioObject);
      }

      final noteObject = backupNote.toObject(
        folder: folderObject,
        tags: noteTagObjects,
        audio: noteAudioObject,
      );
      notes.add(noteObject);

      if (origin != null) {
        for (final segment in origin.transcriptionSegments) {
          segments.add(segment.toObject(note: noteObject));
        }
      }
    }

    return _RestoreGraph(
      folders: folders,
      tags: tags,
      audio: audio,
      notes: notes,
      segments: segments,
    );
  }

  Future<AppDataBackupPayload> _buildCurrentSnapshot() async {
    final (folders, tags, notes) = await (
      _folderRepository.getAll(),
      _tagRepository.getAll(),
      _noteRepository.getAll(),
    ).wait;

    return AppDataBackupPayload(
      settings: AppDataBackupSettings(
        themeMode:
            _sharedPreferences.getString(ThemeCubit.prefsKey) ??
            AppThemeMode.dark.name,
        localeCode:
            _sharedPreferences.getString(LocaleCubit.prefsKey) ??
            AppLocalizations.supportedLocales.first.languageCode,
        recording: AppDataBackupRecordingSettings(
          keepOriginals: _recordingPreferences.keepOriginals,
        ),
        selectedModelId: null,
      ),
      folders: [for (final folder in folders) _mapFolder(folder)],
      tags: [for (final tag in tags) _mapTag(tag)],
      notes: [for (final note in notes) _mapNote(note)],
    );
  }

  AppDataBackupFolder _mapFolder(FolderEntity folder) {
    return AppDataBackupFolder(
      uid: folder.uid,
      name: folder.name,
      description: folder.description,
      colorArgb: folder.color.toARGB32(),
      iconRef: folder.icon.serialize(),
      createdAt: folder.createdAt.toUtc().toIso8601String(),
      updatedAt: folder.updatedAt.toUtc().toIso8601String(),
    );
  }

  AppDataBackupTag _mapTag(TagEntity tag) {
    return AppDataBackupTag(
      name: tag.name,
      colorArgb: tag.color?.toARGB32(),
      createdAt: tag.createdAt.toUtc().toIso8601String(),
    );
  }

  AppDataBackupNote _mapNote(NoteEntity note) {
    final origin = note.origin;
    final audio = origin.audio;
    final transcription = origin.transcription;
    final transcriptionSegments = origin.transcriptionSegments ?? [];

    return AppDataBackupNote(
      uuid: note.uuid,
      folderId: note.folderId,
      text: note.text,
      tagNames: [for (final tag in note.tags) tag.name],
      status: note.status.name,
      failureReason: note.failureReason?.name,
      createdAt: note.createdAt.toUtc().toIso8601String(),
      updatedAt: note.updatedAt.toUtc().toIso8601String(),
      origin: switch (origin) {
        ManualNoteOriginEntity() => const AppDataBackupManualOrigin(),
        AudioNoteOriginEntity() => AppDataBackupAudioOrigin(
          sourceDurationMs: origin.sourceDuration.inMilliseconds,
          audio: audio == null
              ? null
              : AppDataBackupAudioFile(
                  relativePath: audio.relativePath,
                  sizeBytes: audio.sizeBytes,
                  sampleRate: audio.sampleRate,
                  durationMs: audio.duration.inMilliseconds,
                  fileIncluded: true,
                ),
          transcription: transcription == null
              ? null
              : AppDataBackupTranscription(
                  modelId: transcription.modelId.value,
                  languageCode: transcription.languageCode,
                  taskType: transcription.taskType.name,
                  transcribedAt: transcription.transcribedAt
                      .toUtc()
                      .toIso8601String(),
                  processingTimeMs: transcription.processingTime.inMilliseconds,
                  strategyUsed: transcription.strategyUsed.name,
                  usedVad: transcription.usedVad,
                  fellBackFromVad: transcription.fellBackFromVad,
                  emotionLabel: transcription.emotionLabel,
                  eventLabel: transcription.eventLabel,
                  usedItn: transcription.usedItn,
                  usedPunctuation: transcription.usedPunctuation,
                ),
          transcriptionSegments: [
            for (final segment in transcriptionSegments)
              AppDataBackupTranscriptionSegment(
                index: segment.index,
                text: segment.text,
                startMs: segment.start.inMilliseconds,
                endMs: segment.end.inMilliseconds,
                languageCode: segment.languageCode,
                tokens: segment.tokens,
                tokenTimestampsMs: segment.tokenTimestamps
                    ?.map((d) => d.inMilliseconds)
                    .toList(),
              ),
          ],
        ),
      },
    );
  }

  Future<void> _swapImportedRecordings({
    required Directory sourceDir,
    required String targetPath,
  }) async {
    final targetDir = Directory(targetPath);
    if (targetDir.existsSync()) await targetDir.delete(recursive: true);

    if (!sourceDir.existsSync()) {
      await targetDir.create(recursive: true);
      return;
    }

    await sourceDir.rename(targetPath);
  }

  Future<void> _restoreRollbackSnapshot({
    required AppDataBackupPayload snapshot,
    required Directory rollbackRecordingsDir,
    required String recordingsPath,
    required Directory importedRecordingsDir,
  }) async {
    try {
      final graph = _buildRestoreGraph(
        backup: snapshot,
        availableAudioPaths: _allAudioPaths(snapshot),
      );
      await _restoreLocalDataSource.replaceAll(
        folders: graph.folders,
        tags: graph.tags,
        audio: graph.audio,
        notes: graph.notes,
        segments: graph.segments,
      );
    } finally {
      if (importedRecordingsDir.existsSync()) {
        await importedRecordingsDir.delete(recursive: true);
      }

      if (rollbackRecordingsDir.existsSync()) {
        final currentDir = Directory(recordingsPath);
        if (currentDir.existsSync()) await currentDir.delete(recursive: true);
        await rollbackRecordingsDir.rename(recordingsPath);
      }
    }
  }

  int _countMissingAudio(
    Set<String> archiveNames,
    AppDataBackupPayload backup,
  ) {
    int count = 0;
    for (final note in backup.notes) {
      final audio = note.origin.asAudio?.audio;
      if (audio == null || !audio.fileIncluded) continue;
      if (!archiveNames.contains(audio.relativePath)) count += 1;
    }

    return count;
  }

  List<String> _allAudioPaths(AppDataBackupPayload backup) {
    return [
      for (final note in backup.notes)
        if (note.origin.asAudio?.audio case final audio?) audio.relativePath,
    ];
  }

  Future<void> _cleanupSession(Directory sessionDir) async {
    if (!sessionDir.existsSync()) return;
    try {
      await sessionDir.delete(recursive: true);
    } catch (_) {}
  }

  String _recordingsImportPath(String relativePath) {
    const prefix = '${AudioPaths.recordingsSubdir}/';
    if (relativePath.startsWith(prefix)) {
      return relativePath.substring(prefix.length);
    }

    return p.basename(relativePath);
  }
}

class _BackupBundle {
  final Archive archive;
  final AppDataBackupManifest manifest;
  final AppDataBackupPayload backup;

  const _BackupBundle({
    required this.archive,
    required this.manifest,
    required this.backup,
  });
}

_BackupBundle _readBundleFromPath(String filePath) {
  final bytes = File(filePath).readAsBytesSync();
  final archive = AppDataBackupCodec.decodeArchive(bytes);
  final manifest = AppDataBackupCodec.readManifest(archive);
  final backup = AppDataBackupCodec.readBackup(archive);

  return _BackupBundle(archive: archive, manifest: manifest, backup: backup);
}

class _RestoreGraph {
  final List<FolderObject> folders;
  final List<TagObject> tags;
  final List<NoteAudioObject> audio;
  final List<NoteObject> notes;
  final List<NoteTranscriptionSegmentObject> segments;

  const _RestoreGraph({
    required this.folders,
    required this.tags,
    required this.audio,
    required this.notes,
    required this.segments,
  });
}
