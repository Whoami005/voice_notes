import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/import/app_data_import_models.dart';
import 'package:voice_notes/core/packages/import/app_data_import_service.dart';
import 'package:voice_notes/core/packages/import/backup_file_picker_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';
import 'package:voice_notes/core/state/effect/effect_base.dart'
    show EffectCubit;

part 'import_data_sheet_effect.dart';
part 'import_data_sheet_state.dart';

class ImportDataSheetCubit
    extends EffectCubit<ImportDataSheetState, ImportDataSheetEffect> {
  final AppDataImportService _importService;
  final BackupFilePickerService _filePickerService;
  final TranscriptionQueueController _queueController;

  StreamSubscription<TranscriptionQueueSnapshot>? _queueSub;

  ImportDataSheetCubit({
    required AppDataImportService importService,
    required BackupFilePickerService filePickerService,
    required TranscriptionQueueController queueController,
  }) : _importService = importService,
       _filePickerService = filePickerService,
       _queueController = queueController,
       super(
         ImportDataSheetState(activeQueueCount: queueController.current.total),
       ) {
    _queueSub = _queueController.snapshots.listen(
      (snapshot) => safeEmit(state.copyWith(activeQueueCount: snapshot.total)),
      onError: addError,
    );
  }

  bool get _canInteract =>
      !state.isPicking && !state.isInspecting && !state.isImporting;

  Future<void> pickBackupFile() async {
    if (!_canInteract) return;

    safeEmit(state.copyWith(isPicking: true));

    try {
      final file = await _filePickerService.pickBackupFile();
      if (file == null) {
        safeEmit(state.copyWith(isPicking: false));
        return;
      }

      safeEmit(
        state.copyWith(
          isPicking: false,
          isInspecting: true,
          selectedFile: () => null,
          preview: () => null,
        ),
      );

      final preview = await _importService.inspectBackup(file);
      safeEmit(
        state.copyWith(
          isInspecting: false,
          selectedFile: () => file,
          preview: () => preview,
        ),
      );
    } catch (error, stackTrace) {
      safeEmit(
        state.copyWith(
          isPicking: false,
          isInspecting: false,
          selectedFile: () => null,
          preview: () => null,
        ),
      );

      final failure = logError(error, stackTrace);
      emitEffect(
        ShowImportErrorEffect(
          _mapFailureToError(
            failure,
            fallback: ImportDataSheetError.inspectFailed,
          ),
        ),
      );
    }
  }

  Future<AppDataImportResult?> submitImport() async {
    final file = state.selectedFile;
    if (file == null) {
      return _rejectImport(ImportDataSheetError.fileNotSelected);
    }

    if (state.isQueueBusy) {
      return _rejectImport(ImportDataSheetError.queueBusy);
    }

    if (state.isPicking || state.isInspecting || state.isImporting) {
      return _rejectImport(ImportDataSheetError.operationInProgress);
    }

    if (state.preview == null) {
      return _rejectImport(ImportDataSheetError.previewNotReady);
    }

    safeEmit(state.copyWith(isImporting: true));

    try {
      final result = await _importService.importBackup(file: file);
      safeEmit(state.copyWith(isImporting: false));
      return result;
    } catch (error, stackTrace) {
      safeEmit(state.copyWith(isImporting: false));

      final failure = logError(error, stackTrace);
      emitEffect(
        ShowImportErrorEffect(
          _mapFailureToError(
            failure,
            fallback: ImportDataSheetError.importFailed,
          ),
        ),
      );
      return null;
    }
  }

  AppDataImportResult? _rejectImport(ImportDataSheetError error) {
    emitEffect(ShowImportErrorEffect(error));
    return null;
  }

  ImportDataSheetError _mapFailureToError(
    AppFailure failure, {
    required ImportDataSheetError fallback,
  }) {
    return switch (failure) {
      FormatFailure() => ImportDataSheetError.dataProcessingFailed,
      _ => fallback,
    };
  }

  @override
  Future<void> close() async {
    await _queueSub?.cancel();
    return super.close();
  }
}
