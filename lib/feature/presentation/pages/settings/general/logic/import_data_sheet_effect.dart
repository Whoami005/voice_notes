part of 'import_data_sheet_cubit.dart';

sealed class ImportDataSheetEffect implements BaseEffect {
  const ImportDataSheetEffect();
}

enum ImportDataSheetError {
  fileNotSelected,
  previewNotReady,
  operationInProgress,
  queueBusy,
  dataProcessingFailed,
  inspectFailed,
  importFailed,
}

final class ShowImportErrorEffect extends ImportDataSheetEffect {
  final ImportDataSheetError error;

  const ShowImportErrorEffect(this.error);
}
