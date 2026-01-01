import 'dart:io';

import 'package:voice_notes/core/packages/path/app_path_provider.dart';

/// Централизованное управление путями для ASR моделей
class AsrModelPaths {
  AsrModelPaths._();

  static const String modelsSubdir = 'asr_models';
  static const String downloadsSubdir = 'downloads';

  /// Директория для распакованных моделей (Documents/asr_models)
  static Future<String> get modelsDir async {
    final docsDir = await AppPathProvider.getApplicationDocumentsPath;
    return '$docsDir/$modelsSubdir';
  }

  /// Директория для скачанных архивов (Documents/downloads)
  static Future<String> get downloadsDir async {
    final docsDir = await AppPathProvider.getApplicationDocumentsPath;
    return '$docsDir/$downloadsSubdir';
  }

  /// Путь к конкретной модели (Documents/asr_models/{modelDirName})
  static Future<String> modelPath(String modelDirName) async {
    final models = await modelsDir;
    return '$models/$modelDirName';
  }

  /// Путь к архиву модели (Documents/downloads/{modelDirName}.tar.bz2)
  static Future<String> archivePath(String modelDirName) async {
    final downloads = await downloadsDir;
    return '$downloads/$modelDirName.tar.bz2';
  }

  /// Создать необходимые директории
  static Future<void> ensureDirectoriesExist() async {
    final models = await modelsDir;
    final downloads = await downloadsDir;

    await Directory(models).create(recursive: true);
    await Directory(downloads).create(recursive: true);
  }
}
