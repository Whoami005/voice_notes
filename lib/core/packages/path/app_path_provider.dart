import 'dart:io' show Directory;

import 'package:path_provider/path_provider.dart' as path_provider;

class AppPathProvider {
  static Future<Directory> getApplicationDocumentsDirectory() =>
      path_provider.getApplicationDocumentsDirectory();

  static Future<String> get getApplicationDocumentsPath async =>
      (await getApplicationDocumentsDirectory()).path;

  static Future<Directory?> getExternalStorageDirectory() =>
      path_provider.getExternalStorageDirectory();

  static Future<Directory?> getDownloadsDirectory() =>
      path_provider.getDownloadsDirectory();

  static Future<Directory> getTemporaryDirectory() =>
      path_provider.getTemporaryDirectory();
}
