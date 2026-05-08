import 'package:voice_notes/feature/presentation/pages/settings/general/logic/import_data_sheet_cubit.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

extension ImportDataSheetErrorL10n on ImportDataSheetError {
  String message(AppLocalizations l10n) => switch (this) {
    ImportDataSheetError.fileNotSelected =>
      l10n.settingsImportErrorFileNotSelected,
    ImportDataSheetError.previewNotReady =>
      l10n.settingsImportErrorPreviewNotReady,
    ImportDataSheetError.operationInProgress =>
      l10n.settingsImportErrorOperationInProgress,
    ImportDataSheetError.queueBusy => l10n.settingsImportErrorQueueBusy,
    ImportDataSheetError.dataProcessingFailed =>
      l10n.settingsImportErrorDataProcessing,
    ImportDataSheetError.inspectFailed => l10n.settingsImportErrorInspectFailed,
    ImportDataSheetError.importFailed => l10n.settingsImportErrorImportFailed,
  };
}
