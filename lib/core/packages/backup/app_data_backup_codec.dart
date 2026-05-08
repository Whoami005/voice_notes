import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:voice_notes/core/error/app_exception.dart' as app_exc;
import 'package:voice_notes/core/packages/backup/app_data_backup_models.dart';

abstract final class AppDataBackupCodec {
  static const manifestFileName = 'manifest.json';
  static const backupFileName = 'backup.json';

  static String encodeJson(Map<String, Object?> json) {
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  static Archive decodeArchive(Uint8List bytes) {
    return ZipDecoder().decodeBytes(bytes);
  }

  static AppDataBackupManifest readManifest(Archive archive) {
    final raw = _readTextFile(archive, manifestFileName);

    return app_exc.FormatException.parseJson(
      () => AppDataBackupManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      ),
      manifestFileName,
    );
  }

  static AppDataBackupPayload readBackup(Archive archive) {
    final raw = _readTextFile(archive, backupFileName);

    return app_exc.FormatException.parseJson(
      () => AppDataBackupPayload.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      ),
      backupFileName,
    );
  }

  static String _readTextFile(Archive archive, String name) {
    final entry = archive.files.firstWhere(
      (file) => file.name == name,
      orElse: () => throw app_exc.CustomException.notFound(name),
    );

    final content = entry.content as Uint8List?;
    if (content == null) {
      throw app_exc.FormatException.json('Invalid file content: $name');
    }

    return utf8.decode(content);
  }
}
