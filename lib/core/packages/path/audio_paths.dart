import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:voice_notes/core/packages/path/app_path_provider.dart';

/// Централизованное управление путями для аудиофайлов приложения.
///
/// Хранит относительные пути в БД; резолвит их в абсолютные в рантайме
/// через [AppPathProvider.getApplicationDocumentsPath]. Такой подход
/// переживает изменение контейнера приложения на iOS между билдами.
///
/// Структура на диске:
/// ```text
/// Documents/
/// └── audio/
///     ├── recordings/   — оригинальные записи, привязанные к заметкам
///     └── tts/          — синтезированные аудио (Plan 2)
/// ```
class AudioPaths {
  AudioPaths._();

  static const String audioSubdir = 'audio';
  static const String recordingsSubdir = 'audio/recordings';
  static const String ttsSubdir = 'audio/tts';

  /// Директория оригинальных записей (Documents/audio/recordings).
  ///
  /// Гарантирует существование директории при каждом обращении.
  /// `Directory.create(recursive: true)` — no-op если уже существует.
  static Future<String> get recordingsDir async {
    final docsDir = await AppPathProvider.getApplicationDocumentsPath;
    final dir = Directory(p.join(docsDir, recordingsSubdir));

    await dir.create(recursive: true);

    return dir.path;
  }

  /// Дирек��ория синтезированных TTS-аудио (Documents/audio/tts).
  ///
  /// Гарантирует существование директории при каждом обращении.
  static Future<String> get ttsDir async {
    final docsDir = await AppPathProvider.getApplicationDocumentsPath;
    final dir = Directory(p.join(docsDir, ttsSubdir));

    await dir.create(recursive: true);

    return dir.path;
  }

  /// Относительный путь к файлу записи (для хранения в БД)
  static String recordingRelativePath(String noteUuid) {
    return p.join(recordingsSubdir, '$noteUuid.wav');
  }

  /// Относительный путь к файлу TTS-генерации (для хранения в БД)
  static String ttsRelativePath(String generationUuid) {
    return p.join(ttsSubdir, '$generationUuid.wav');
  }

  /// Восстановить полный путь из относительного
  static Future<String> resolveRelativePath(String relativePath) async {
    final docsDir = await AppPathProvider.getApplicationDocumentsPath;
    return p.join(docsDir, relativePath);
  }

  /// Best-effort удаление файла по относительному пути.
  static Future<void> deleteFile(String relativePath) async {
    try {
      final absolutePath = await resolveRelativePath(relativePath);
      final file = File(absolutePath);

      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
