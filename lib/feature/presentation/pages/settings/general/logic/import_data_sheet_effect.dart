part of 'import_data_sheet_cubit.dart';

sealed class ImportDataSheetEffect implements BaseEffect {
  const ImportDataSheetEffect();
}

final class ShowImportErrorEffect extends ImportDataSheetEffect {
  final String message;

  const ShowImportErrorEffect(this.message);
}
