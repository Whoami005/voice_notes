import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:voice_notes/core/packages/asr/asr_vad_asset_installer.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'asr_vad_asset_installer_test',
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  AsrVadAssetInstaller buildInstaller({
    required List<int> assetBytes,
    Future<ByteData> Function(String assetKey)? assetLoader,
  }) {
    final destinationPath = path.join(tempDir.path, 'silero_vad.onnx');

    return AsrVadAssetInstaller(
      assetLoader:
          assetLoader ??
          (_) async => ByteData.sublistView(Uint8List.fromList(assetBytes)),
      destinationPathProvider: () async => destinationPath,
      ensureDirectoriesExist: () async => tempDir.create(recursive: true),
      findInstalledModelPath: () async {
        final file = File(destinationPath);
        return file.existsSync() ? destinationPath : null;
      },
    );
  }

  group('AsrVadAssetInstaller', () {
    test(
      'resolveModelPath copies bundled asset when file is missing',
      () async {
        final installer = buildInstaller(assetBytes: [1, 2, 3, 4]);

        final installedPath = await installer.resolveModelPath();
        final installedFile = File(path.join(tempDir.path, 'silero_vad.onnx'));

        expect(installedPath, installedFile.path);
        expect(installedFile.existsSync(), isTrue);
        expect(await installedFile.readAsBytes(), [1, 2, 3, 4]);
      },
    );

    test(
      'ensureInstalled replaces existing file when bundled asset changed',
      () async {
        final installedFile = File(path.join(tempDir.path, 'silero_vad.onnx'));
        await installedFile.writeAsBytes([7, 8, 9], flush: true);

        final installer = buildInstaller(assetBytes: [1, 2, 3, 4, 5]);
        await installer.ensureInstalled();

        expect(await installedFile.readAsBytes(), [1, 2, 3, 4, 5]);
      },
    );

    test(
      'resolveModelPath returns existing file without loading asset again',
      () async {
        final installedFile = File(path.join(tempDir.path, 'silero_vad.onnx'));
        await installedFile.writeAsBytes([4, 5, 6], flush: true);

        final installer = buildInstaller(
          assetBytes: const [],
          assetLoader: (_) async => throw StateError('asset should not load'),
        );

        final installedPath = await installer.resolveModelPath();

        expect(installedPath, installedFile.path);
        expect(await installedFile.readAsBytes(), [4, 5, 6]);
      },
    );
  });
}
