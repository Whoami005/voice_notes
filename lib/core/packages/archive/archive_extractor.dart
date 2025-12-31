import 'dart:io';

import 'package:archive/archive_io.dart';

/// Утилита для распаковки архивов
class ArchiveExtractor {
  const ArchiveExtractor._();

  /// Распаковать tar.bz2 архив в указанную директорию
  ///
  /// [archivePath] - путь к архиву
  /// [destinationDir] - директория для распаковки
  ///
  /// После успешной распаковки архив удаляется
  static Future<void> extractTarBz2({
    required String archivePath,
    required String destinationDir,
  }) async {
    final destinationDirectory = Directory(destinationDir);
    if (!destinationDirectory.existsSync()) {
      await destinationDirectory.create(recursive: true);
    }

    // Используем extractFileToDisk который автоматически определяет тип архива
    // по расширению файла и распаковывает его
    await Future(() => extractFileToDisk(archivePath, destinationDir));

    // Удаляем архив после успешной распаковки
    final archiveFile = File(archivePath);
    if (archiveFile.existsSync()) {
      await archiveFile.delete();
    }
  }

  /// Распаковать архив без удаления оригинала
  static Future<void> extractTarBz2KeepArchive({
    required String archivePath,
    required String destinationDir,
  }) async {
    final destinationDirectory = Directory(destinationDir);
    if (!destinationDirectory.existsSync()) {
      await destinationDirectory.create(recursive: true);
    }

    await Future(() => extractFileToDisk(archivePath, destinationDir));
  }
}
