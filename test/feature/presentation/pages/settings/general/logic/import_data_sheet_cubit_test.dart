import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:voice_notes/core/error/app_exception.dart' as app_exc;
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/backup/app_data_backup_models.dart';
import 'package:voice_notes/core/packages/import/app_data_import_models.dart';
import 'package:voice_notes/core/packages/import/app_data_import_service.dart';
import 'package:voice_notes/core/packages/import/backup_file_picker_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/logic/import_data_sheet_cubit.dart';

void main() {
  late _FakeBackupFilePickerService filePickerService;
  late _FakeAppDataImportService importService;
  late _FakeTranscriptionQueueController queueController;
  late Directory tempDir;
  late XFile backupFile;

  setUp(() async {
    filePickerService = _FakeBackupFilePickerService();
    importService = _FakeAppDataImportService();
    queueController = _FakeTranscriptionQueueController();

    tempDir = await Directory.systemTemp.createTemp('import-data-sheet-cubit');
    final file = File(p.join(tempDir.path, 'backup.zip'));
    await file.writeAsBytes(const [1, 2, 3], flush: true);
    backupFile = XFile(file.path);

    filePickerService.result = backupFile;
    importService.preview = _previewFor(fileName: backupFile.name);
  });

  tearDown(() async {
    await queueController.dispose();

    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  ImportDataSheetCubit buildCubit() {
    return ImportDataSheetCubit(
      importService: importService,
      filePickerService: filePickerService,
      queueController: queueController,
    );
  }

  group('ImportDataSheetCubit.submitImport', () {
    test(
      'returns null and emits file-not-selected effect when no file chosen',
      () async {
        final cubit = buildCubit();
        addTearDown(cubit.close);

        final effectFuture = cubit.effects.first;
        final result = await cubit.submitImport();

        expect(result, isNull);
        expect(
          await effectFuture,
          isA<ShowImportErrorEffect>().having(
            (effect) => effect.error,
            'error',
            ImportDataSheetError.fileNotSelected,
          ),
        );
        expect(cubit.state.isImporting, isFalse);
      },
    );

    test(
      'returns null and emits queue-busy effect when queue has active items',
      () async {
        queueController.currentSnapshot = const TranscriptionQueueSnapshot(
          queued: ['queued-note'],
        );
        final cubit = buildCubit();
        addTearDown(cubit.close);

        await cubit.pickBackupFile();

        final effectFuture = cubit.effects.first;
        final result = await cubit.submitImport();

        expect(result, isNull);
        expect(
          await effectFuture,
          isA<ShowImportErrorEffect>().having(
            (effect) => effect.error,
            'error',
            ImportDataSheetError.queueBusy,
          ),
        );
        expect(importService.importedFiles, isEmpty);
        expect(cubit.state.isImporting, isFalse);
      },
    );

    test('returns null, resets loading state and emits processing error '
        'when import fails', () async {
      importService.importImpl = (_) async {
        throw const app_exc.FormatException.json('broken backup');
      };
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.pickBackupFile();

      final importingStates = <bool>[];
      final stateSub = cubit.stream.listen(
        (state) => importingStates.add(state.isImporting),
      );
      addTearDown(stateSub.cancel);

      final effectFuture = cubit.effects.first;
      final result = await cubit.submitImport();

      expect(result, isNull);
      expect(
        await effectFuture,
        isA<ShowImportErrorEffect>().having(
          (effect) => effect.error,
          'error',
          ImportDataSheetError.dataProcessingFailed,
        ),
      );
      expect(importingStates, [true, false]);
      expect(cubit.state.isImporting, isFalse);
    });

    test('returns imported backup result when import succeeds', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      await cubit.pickBackupFile();

      final result = await cubit.submitImport();

      expect(result, _successResult());
      expect(importService.importedFiles, [backupFile.path]);
      expect(cubit.state.isImporting, isFalse);
    });
  });
}

AppDataImportPreview _previewFor({required String fileName}) {
  return AppDataImportPreview(
    fileName: fileName,
    manifest: const AppDataBackupManifest(
      schemaVersion: 1,
      app: 'voice_notes',
      exportedAt: '2026-05-08T12:30:45.000Z',
      includesAudio: true,
      counts: AppDataBackupCounts(folders: 1, tags: 1, notes: 2, audioFiles: 1),
    ),
    warningsCount: 0,
  );
}

AppDataImportResult _successResult({bool withWarnings = false}) {
  return AppDataImportResult(
    backup: const AppDataBackupPayload(
      settings: AppDataBackupSettings(
        themeMode: 'light',
        localeCode: 'en',
        recording: AppDataBackupRecordingSettings(keepOriginals: false),
        selectedModelId: null,
      ),
      folders: [],
      tags: [],
      notes: [],
    ),
    warnings: withWarnings
        ? const [MissingAudioImportWarning(count: 1)]
        : const [],
    restoredFoldersCount: 1,
    restoredTagsCount: 1,
    restoredNotesCount: 2,
    restoredAudioCount: 1,
  );
}

class _FakeBackupFilePickerService implements BackupFilePickerService {
  XFile? result;

  @override
  Future<XFile?> pickBackupFile() async => result;
}

class _FakeAppDataImportService implements AppDataImportService {
  AppDataImportPreview preview = _previewFor(fileName: 'backup.zip');
  Future<AppDataImportPreview> Function(XFile file)? inspectImpl;
  Future<AppDataImportResult> Function(XFile file)? importImpl;

  final List<String> inspectedFiles = [];
  final List<String> importedFiles = [];

  @override
  Future<AppDataImportPreview> inspectBackup(XFile file) async {
    inspectedFiles.add(file.path);
    final handler = inspectImpl;
    if (handler != null) return handler(file);

    return preview;
  }

  @override
  Future<AppDataImportResult> importBackup({required XFile file}) async {
    importedFiles.add(file.path);
    final handler = importImpl;
    if (handler != null) return handler(file);

    return _successResult();
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
