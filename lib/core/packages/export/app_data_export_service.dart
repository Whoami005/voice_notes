import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/export/app_data_export_models.dart';
import 'package:voice_notes/core/packages/path/app_path_provider.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_origin_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_meta_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_segment_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';
import 'package:voice_notes/feature/domain/repositories/tag_repository.dart';

typedef TempDirectoryProvider = Future<Directory> Function();
typedef AudioPathResolver = Future<String> Function(String relativePath);
typedef ExportClock = DateTime Function();

abstract interface class AppDataExportService {
  Future<AppDataExportSummary> getSummary();

  Future<ExportArtifact> createBackup({required AppDataExportOptions options});
}

@Singleton(as: AppDataExportService)
class AppDataExportServiceImpl implements AppDataExportService {
  static const _schemaVersion = 1;
  static const _appName = 'voice_notes';
  static const _exportsDirName = 'voice_notes_exports';
  static const _filePrefix = 'voice-notes-backup-';
  static const _fileSuffix = '.zip';

  final FolderRepository _folderRepository;
  final TagRepository _tagRepository;
  final NoteRepository _noteRepository;
  final StorageStatsRepository _storageStatsRepository;
  final ModelRepository _modelRepository;
  final RecordingPreferences _recordingPreferences;
  final SharedPreferences _sharedPreferences;
  final ExportClock _now;
  final TempDirectoryProvider _tempDirectoryProvider;
  final AudioPathResolver _audioPathResolver;

  AppDataExportServiceImpl({
    required FolderRepository folderRepository,
    required TagRepository tagRepository,
    required NoteRepository noteRepository,
    required StorageStatsRepository storageStatsRepository,
    required ModelRepository modelRepository,
    required RecordingPreferences recordingPreferences,
    required SharedPreferences sharedPreferences,
  }) : _folderRepository = folderRepository,
       _tagRepository = tagRepository,
       _noteRepository = noteRepository,
       _storageStatsRepository = storageStatsRepository,
       _modelRepository = modelRepository,
       _recordingPreferences = recordingPreferences,
       _sharedPreferences = sharedPreferences,
       _now = DateTime.now,
       _tempDirectoryProvider = AppPathProvider.getTemporaryDirectory,
       _audioPathResolver = AudioPaths.resolveRelativePath;

  @visibleForTesting
  AppDataExportServiceImpl.test({
    required FolderRepository folderRepository,
    required TagRepository tagRepository,
    required NoteRepository noteRepository,
    required StorageStatsRepository storageStatsRepository,
    required ModelRepository modelRepository,
    required RecordingPreferences recordingPreferences,
    required SharedPreferences sharedPreferences,
    ExportClock? now,
    TempDirectoryProvider? tempDirectoryProvider,
    AudioPathResolver? audioPathResolver,
  }) : _folderRepository = folderRepository,
       _tagRepository = tagRepository,
       _noteRepository = noteRepository,
       _storageStatsRepository = storageStatsRepository,
       _modelRepository = modelRepository,
       _recordingPreferences = recordingPreferences,
       _sharedPreferences = sharedPreferences,
       _now = now ?? DateTime.now,
       _tempDirectoryProvider =
           tempDirectoryProvider ?? AppPathProvider.getTemporaryDirectory,
       _audioPathResolver = audioPathResolver ?? AudioPaths.resolveRelativePath;

  @override
  Future<AppDataExportSummary> getSummary() async {
    final (notes, overview) = await (
      _noteRepository.getAll(),
      _storageStatsRepository.getOverview(),
    ).wait;

    return AppDataExportSummary(
      notesCount: notes.length,
      audioCount: overview.totalCount,
      audioBytes: overview.totalBytes,
    );
  }

  @override
  Future<ExportArtifact> createBackup({
    required AppDataExportOptions options,
  }) async {
    final exportedAt = _now().toUtc();
    final exportDir = await _prepareExportDirectory();
    final fileName = _buildFileName(exportedAt);
    final archiveFile = File(p.join(exportDir.path, fileName));
    if (archiveFile.existsSync()) await archiveFile.delete();

    final preparedBackup = await _prepareBackup(
      exportedAt: exportedAt,
      includeAudio: options.includeAudio,
    );

    final encoder = ZipFileEncoder()..create(archiveFile.path);

    try {
      encoder
        ..addArchiveFile(
          ArchiveFile.string(
            'manifest.json',
            const JsonEncoder.withIndent(
              '  ',
            ).convert(preparedBackup.manifest.toJson()),
          ),
        )
        ..addArchiveFile(
          ArchiveFile.string(
            'backup.json',
            const JsonEncoder.withIndent(
              '  ',
            ).convert(preparedBackup.backup.toJson()),
          ),
        );

      for (final audioFile in preparedBackup.audioFiles) {
        await encoder.addFile(audioFile.file, audioFile.archivePath);
      }
    } finally {
      unawaited(encoder.close());
    }

    return ExportArtifact(
      file: archiveFile,
      fileName: fileName,
      exportedAt: exportedAt,
      includesAudio: options.includeAudio,
    );
  }

  Future<Directory> _prepareExportDirectory() async {
    final root = await _tempDirectoryProvider();
    final directory = Directory(p.join(root.path, _exportsDirName));
    await directory.create(recursive: true);
    await _cleanupStaleArchives(directory);

    return directory;
  }

  Future<void> _cleanupStaleArchives(Directory directory) async {
    if (!directory.existsSync()) return;

    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;

      final name = p.basename(entity.path);
      final isBackup =
          name.startsWith(_filePrefix) && name.endsWith(_fileSuffix);
      if (isBackup) await entity.delete();
    }
  }

  String _buildFileName(DateTime exportedAt) {
    final formatter = DateFormat('yyyyMMdd-HHmmss');
    return '$_filePrefix${formatter.format(exportedAt.toLocal())}$_fileSuffix';
  }

  Future<_PreparedBackup> _prepareBackup({
    required DateTime exportedAt,
    required bool includeAudio,
  }) async {
    final (folders, tags, notes, selectedModel) = await (
      _folderRepository.getAll(),
      _tagRepository.getAll(),
      _noteRepository.getAll(),
      _modelRepository.getSelectedModel(),
    ).wait;

    final audioFiles = <_PreparedAudioFile>[];
    final exportedNotes = <_ExportNoteDto>[];

    for (final note in notes) {
      final preparedNote = await _prepareNote(note, includeAudio: includeAudio);
      exportedNotes.add(preparedNote.note);
      audioFiles.addAll(preparedNote.audioFiles);
    }

    final backup = _ExportBackupDto(
      settings: _ExportSettingsDto(
        themeMode: ThemeCubit.readMode(_sharedPreferences).name,
        localeCode: LocaleCubit.readLocale(_sharedPreferences).languageCode,
        recording: _ExportRecordingSettingsDto(
          keepOriginals: _recordingPreferences.keepOriginals,
        ),
        selectedModelId: selectedModel?.uuid.value,
      ),
      folders: [for (final folder in folders) _mapFolder(folder)],
      tags: [for (final tag in tags) _mapTag(tag)],
      notes: exportedNotes,
    );

    final manifest = _ExportManifestDto(
      schemaVersion: _schemaVersion,
      app: _appName,
      exportedAt: exportedAt.toIso8601String(),
      includesAudio: includeAudio,
      counts: _ExportCountsDto(
        folders: folders.length,
        tags: tags.length,
        notes: exportedNotes.length,
        audioFiles: audioFiles.length,
      ),
    );

    return _PreparedBackup(
      manifest: manifest,
      backup: backup,
      audioFiles: audioFiles,
    );
  }

  Future<_PreparedNote> _prepareNote(
    NoteEntity note, {
    required bool includeAudio,
  }) async {
    final audioFiles = <_PreparedAudioFile>[];
    final origin = note.origin;

    final originDto = switch (origin) {
      ManualNoteOriginEntity() => const _ExportManualOriginDto(),
      AudioNoteOriginEntity() => await _prepareAudioOrigin(
        origin,
        includeAudio: includeAudio,
        audioFiles: audioFiles,
      ),
    };

    return _PreparedNote(
      note: _ExportNoteDto(
        uuid: note.uuid,
        folderId: note.folderId,
        text: note.text,
        tagNames: [for (final tag in note.tags) tag.name],
        status: note.status.name,
        failureReason: note.failureReason?.name,
        createdAt: note.createdAt.toUtc().toIso8601String(),
        updatedAt: note.updatedAt.toUtc().toIso8601String(),
        origin: originDto,
      ),
      audioFiles: audioFiles,
    );
  }

  Future<_ExportAudioOriginDto> _prepareAudioOrigin(
    AudioNoteOriginEntity origin, {
    required bool includeAudio,
    required List<_PreparedAudioFile> audioFiles,
  }) async {
    final audioDto = await _prepareAudioFile(
      origin.audio,
      includeAudio: includeAudio,
      audioFiles: audioFiles,
    );

    return _ExportAudioOriginDto(
      sourceDurationMs: origin.sourceDuration.inMilliseconds,
      audio: audioDto,
      transcription: _mapTranscription(origin.transcription),
      transcriptionSegments: [
        for (final segment
            in origin.transcriptionSegments ??
                const <NoteTranscriptionSegmentEntity>[])
          _mapSegment(segment),
      ],
    );
  }

  Future<_ExportAudioFileDto?> _prepareAudioFile(
    NoteAudioEntity? audio, {
    required bool includeAudio,
    required List<_PreparedAudioFile> audioFiles,
  }) async {
    if (audio == null) return null;

    final absolutePath = await _audioPathResolver(audio.relativePath);
    final file = File(absolutePath);
    final fileIncluded = includeAudio && file.existsSync();

    if (fileIncluded) {
      audioFiles.add(
        _PreparedAudioFile(file: file, archivePath: audio.relativePath),
      );
    }

    return _ExportAudioFileDto(
      relativePath: audio.relativePath,
      sizeBytes: audio.sizeBytes,
      sampleRate: audio.sampleRate,
      durationMs: audio.duration.inMilliseconds,
      fileIncluded: fileIncluded,
    );
  }

  _ExportFolderDto _mapFolder(FolderEntity folder) {
    return _ExportFolderDto(
      uid: folder.uid,
      name: folder.name,
      description: folder.description,
      colorArgb: folder.color.toARGB32(),
      iconRef: folder.icon.serialize(),
      createdAt: folder.createdAt.toUtc().toIso8601String(),
      updatedAt: folder.updatedAt.toUtc().toIso8601String(),
    );
  }

  _ExportTagDto _mapTag(TagEntity tag) {
    return _ExportTagDto(
      name: tag.name,
      colorArgb: tag.color?.toARGB32(),
      createdAt: tag.createdAt.toUtc().toIso8601String(),
    );
  }

  _ExportTranscriptionDto? _mapTranscription(
    NoteTranscriptionMetaEntity? transcription,
  ) {
    if (transcription == null) return null;

    return _ExportTranscriptionDto(
      modelId: transcription.modelId.value,
      languageCode: transcription.languageCode,
      taskType: transcription.taskType.name,
      transcribedAt: transcription.transcribedAt.toUtc().toIso8601String(),
      processingTimeMs: transcription.processingTime.inMilliseconds,
      strategyUsed: transcription.strategyUsed.name,
      usedVad: transcription.usedVad,
      fellBackFromVad: transcription.fellBackFromVad,
      emotionLabel: transcription.emotionLabel,
      eventLabel: transcription.eventLabel,
      usedItn: transcription.usedItn,
      usedPunctuation: transcription.usedPunctuation,
    );
  }

  _ExportTranscriptionSegmentDto _mapSegment(
    NoteTranscriptionSegmentEntity segment,
  ) {
    return _ExportTranscriptionSegmentDto(
      index: segment.index,
      text: segment.text,
      startMs: segment.start.inMilliseconds,
      endMs: segment.end.inMilliseconds,
      languageCode: segment.languageCode,
      tokens: segment.tokens,
      tokenTimestampsMs: segment.tokenTimestamps
          ?.map((timestamp) => timestamp.inMilliseconds)
          .toList(),
    );
  }
}

class _PreparedBackup {
  final _ExportManifestDto manifest;
  final _ExportBackupDto backup;
  final List<_PreparedAudioFile> audioFiles;

  const _PreparedBackup({
    required this.manifest,
    required this.backup,
    required this.audioFiles,
  });
}

class _PreparedNote {
  final _ExportNoteDto note;
  final List<_PreparedAudioFile> audioFiles;

  const _PreparedNote({required this.note, required this.audioFiles});
}

class _PreparedAudioFile {
  final File file;
  final String archivePath;

  const _PreparedAudioFile({required this.file, required this.archivePath});
}

class _ExportManifestDto {
  final int schemaVersion;
  final String app;
  final String exportedAt;
  final bool includesAudio;
  final _ExportCountsDto counts;

  const _ExportManifestDto({
    required this.schemaVersion,
    required this.app,
    required this.exportedAt,
    required this.includesAudio,
    required this.counts,
  });

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'app': app,
    'exportedAt': exportedAt,
    'includesAudio': includesAudio,
    'counts': counts.toJson(),
  };
}

class _ExportCountsDto {
  final int folders;
  final int tags;
  final int notes;
  final int audioFiles;

  const _ExportCountsDto({
    required this.folders,
    required this.tags,
    required this.notes,
    required this.audioFiles,
  });

  Map<String, Object?> toJson() => {
    'folders': folders,
    'tags': tags,
    'notes': notes,
    'audioFiles': audioFiles,
  };
}

class _ExportBackupDto {
  final _ExportSettingsDto settings;
  final List<_ExportFolderDto> folders;
  final List<_ExportTagDto> tags;
  final List<_ExportNoteDto> notes;

  const _ExportBackupDto({
    required this.settings,
    required this.folders,
    required this.tags,
    required this.notes,
  });

  Map<String, Object?> toJson() => {
    'settings': settings.toJson(),
    'folders': [for (final folder in folders) folder.toJson()],
    'tags': [for (final tag in tags) tag.toJson()],
    'notes': [for (final note in notes) note.toJson()],
  };
}

class _ExportSettingsDto {
  final String themeMode;
  final String localeCode;
  final _ExportRecordingSettingsDto recording;
  final String? selectedModelId;

  const _ExportSettingsDto({
    required this.themeMode,
    required this.localeCode,
    required this.recording,
    required this.selectedModelId,
  });

  Map<String, Object?> toJson() => {
    'themeMode': themeMode,
    'localeCode': localeCode,
    'recording': recording.toJson(),
    'selectedModelId': selectedModelId,
  };
}

class _ExportRecordingSettingsDto {
  final bool keepOriginals;

  const _ExportRecordingSettingsDto({required this.keepOriginals});

  Map<String, Object?> toJson() => {'keepOriginals': keepOriginals};
}

class _ExportFolderDto {
  final String uid;
  final String name;
  final String? description;
  final int colorArgb;
  final String iconRef;
  final String createdAt;
  final String updatedAt;

  const _ExportFolderDto({
    required this.uid,
    required this.name,
    required this.description,
    required this.colorArgb,
    required this.iconRef,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toJson() => {
    'uid': uid,
    'name': name,
    'description': description,
    'colorArgb': colorArgb,
    'iconRef': iconRef,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

class _ExportTagDto {
  final String name;
  final int? colorArgb;
  final String createdAt;

  const _ExportTagDto({
    required this.name,
    required this.colorArgb,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'colorArgb': colorArgb,
    'createdAt': createdAt,
  };
}

class _ExportNoteDto {
  final String uuid;
  final String? folderId;
  final String text;
  final List<String> tagNames;
  final String status;
  final String? failureReason;
  final String createdAt;
  final String updatedAt;
  final _ExportNoteOriginDto origin;

  const _ExportNoteDto({
    required this.uuid,
    required this.folderId,
    required this.text,
    required this.tagNames,
    required this.status,
    required this.failureReason,
    required this.createdAt,
    required this.updatedAt,
    required this.origin,
  });

  Map<String, Object?> toJson() => {
    'uuid': uuid,
    'folderId': folderId,
    'text': text,
    'tagNames': tagNames,
    'status': status,
    'failureReason': failureReason,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'origin': origin.toJson(),
  };
}

sealed class _ExportNoteOriginDto {
  const _ExportNoteOriginDto();

  Map<String, Object?> toJson();
}

class _ExportManualOriginDto extends _ExportNoteOriginDto {
  const _ExportManualOriginDto();

  @override
  Map<String, Object?> toJson() => {'type': 'manual'};
}

class _ExportAudioOriginDto extends _ExportNoteOriginDto {
  final int sourceDurationMs;
  final _ExportAudioFileDto? audio;
  final _ExportTranscriptionDto? transcription;
  final List<_ExportTranscriptionSegmentDto> transcriptionSegments;

  const _ExportAudioOriginDto({
    required this.sourceDurationMs,
    required this.audio,
    required this.transcription,
    required this.transcriptionSegments,
  });

  @override
  Map<String, Object?> toJson() => {
    'type': 'audio',
    'sourceDurationMs': sourceDurationMs,
    'audio': audio?.toJson(),
    'transcription': transcription?.toJson(),
    'transcriptionSegments': [
      for (final segment in transcriptionSegments) segment.toJson(),
    ],
  };
}

class _ExportAudioFileDto {
  final String relativePath;
  final int sizeBytes;
  final int sampleRate;
  final int durationMs;
  final bool fileIncluded;

  const _ExportAudioFileDto({
    required this.relativePath,
    required this.sizeBytes,
    required this.sampleRate,
    required this.durationMs,
    required this.fileIncluded,
  });

  Map<String, Object?> toJson() => {
    'relativePath': relativePath,
    'sizeBytes': sizeBytes,
    'sampleRate': sampleRate,
    'durationMs': durationMs,
    'fileIncluded': fileIncluded,
  };
}

class _ExportTranscriptionDto {
  final String modelId;
  final String? languageCode;
  final String taskType;
  final String transcribedAt;
  final int processingTimeMs;
  final String strategyUsed;
  final bool usedVad;
  final bool fellBackFromVad;
  final String? emotionLabel;
  final String? eventLabel;
  final bool? usedItn;
  final bool? usedPunctuation;

  const _ExportTranscriptionDto({
    required this.modelId,
    required this.languageCode,
    required this.taskType,
    required this.transcribedAt,
    required this.processingTimeMs,
    required this.strategyUsed,
    required this.usedVad,
    required this.fellBackFromVad,
    required this.emotionLabel,
    required this.eventLabel,
    required this.usedItn,
    required this.usedPunctuation,
  });

  Map<String, Object?> toJson() => {
    'modelId': modelId,
    'languageCode': languageCode,
    'taskType': taskType,
    'transcribedAt': transcribedAt,
    'processingTimeMs': processingTimeMs,
    'strategyUsed': strategyUsed,
    'usedVad': usedVad,
    'fellBackFromVad': fellBackFromVad,
    'emotionLabel': emotionLabel,
    'eventLabel': eventLabel,
    'usedItn': usedItn,
    'usedPunctuation': usedPunctuation,
  };
}

class _ExportTranscriptionSegmentDto {
  final int index;
  final String text;
  final int startMs;
  final int endMs;
  final String? languageCode;
  final List<String>? tokens;
  final List<int>? tokenTimestampsMs;

  const _ExportTranscriptionSegmentDto({
    required this.index,
    required this.text,
    required this.startMs,
    required this.endMs,
    required this.languageCode,
    required this.tokens,
    required this.tokenTimestampsMs,
  });

  Map<String, Object?> toJson() => {
    'index': index,
    'text': text,
    'startMs': startMs,
    'endMs': endMs,
    'languageCode': languageCode,
    'tokens': tokens,
    'tokenTimestampsMs': tokenTimestampsMs,
  };
}
