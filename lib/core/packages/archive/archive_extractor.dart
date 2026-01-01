import 'dart:async';
import 'dart:io';
import 'dart:isolate';

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
    await _createDirectory(destinationDir);

    // Используем Isolate.run для выполнения в фоновом изоляте
    // extractFileToDisk автоматически определяет тип архива по расширению
    await Isolate.run(() => extractFileToDisk(archivePath, destinationDir));

    // Удаляем архив после успешной распаковки
    final archiveFile = File(archivePath);
    if (archiveFile.existsSync()) unawaited(archiveFile.delete());
  }

  /// Распаковать архив без удаления оригинала
  static Future<void> extractTarBz2KeepArchive({
    required String archivePath,
    required String destinationDir,
  }) async {
    await _createDirectory(destinationDir);

    await Isolate.run(() => extractFileToDisk(archivePath, destinationDir));
  }

  static Future<void> _createDirectory(String path) async {
    final destinationDirectory = Directory(path);

    if (!destinationDirectory.existsSync()) {
      await destinationDirectory.create(recursive: true);
    }
  }
}
