import 'package:cross_file/cross_file.dart';
import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/backup/app_data_backup_models.dart';

class AppDataImportPreview extends Equatable {
  final String fileName;
  final AppDataBackupManifest manifest;
  final int warningsCount;

  const AppDataImportPreview({
    required this.fileName,
    required this.manifest,
    required this.warningsCount,
  });

  int get foldersCount => manifest.counts.folders;

  int get tagsCount => manifest.counts.tags;

  int get notesCount => manifest.counts.notes;

  int get audioFilesCount => manifest.counts.audioFiles;

  bool get includesAudio => manifest.includesAudio;

  String get exportedAt => manifest.exportedAt;

  int get schemaVersion => manifest.schemaVersion;

  @override
  List<Object?> get props => [fileName, manifest, warningsCount];
}

class AppDataImportResult extends Equatable {
  final AppDataBackupPayload backup;
  final List<AppDataImportWarning> warnings;
  final int restoredFoldersCount;
  final int restoredTagsCount;
  final int restoredNotesCount;
  final int restoredAudioCount;

  const AppDataImportResult({
    required this.backup,
    required this.warnings,
    required this.restoredFoldersCount,
    required this.restoredTagsCount,
    required this.restoredNotesCount,
    required this.restoredAudioCount,
  });

  AppDataBackupSettings get settings => backup.settings;

  bool get hasWarnings => warnings.isNotEmpty;

  int get warningsCount => warnings.length;

  @override
  List<Object?> get props => [
    backup,
    warnings,
    restoredFoldersCount,
    restoredTagsCount,
    restoredNotesCount,
    restoredAudioCount,
  ];
}

sealed class AppDataImportWarning extends Equatable {
  const AppDataImportWarning();
}

final class MissingAudioImportWarning extends AppDataImportWarning {
  final int count;

  const MissingAudioImportWarning({required this.count});

  @override
  List<Object?> get props => [count];
}

final class SettingsImportWarning extends AppDataImportWarning {
  final List<String> fields;

  const SettingsImportWarning({required this.fields});

  @override
  List<Object?> get props => [fields];
}

final class BackupFileSelection extends Equatable {
  final XFile file;

  const BackupFileSelection(this.file);

  @override
  List<Object?> get props => [file];
}
