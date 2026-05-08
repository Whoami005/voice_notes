import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

abstract interface class BackupFilePickerService {
  Future<XFile?> pickBackupFile();
}

@Singleton(as: BackupFilePickerService)
class BackupFilePickerServiceImpl implements BackupFilePickerService {
  @override
  Future<XFile?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );

    if (result == null || result.files.isEmpty) return null;

    return result.files.first.xFile;
  }
}
