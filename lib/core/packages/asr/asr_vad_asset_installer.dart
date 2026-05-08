import 'dart:io';

import 'package:flutter/services.dart';
import 'package:voice_notes/core/packages/path/asr_model_paths.dart';

class AsrVadAssetInstaller {
  final Future<ByteData> Function(String assetKey) _assetLoader;
  final Future<String> Function() _destinationPathProvider;
  final Future<void> Function() _ensureDirectoriesExist;
  final Future<String?> Function() _findInstalledModelPath;

  static const String assetPath = 'assets/models/silero_vad.onnx';
  static const String vadModelFileName = AsrModelPaths.vadModelFileName;

  AsrVadAssetInstaller({
    Future<ByteData> Function(String assetKey)? assetLoader,
    Future<String> Function()? destinationPathProvider,
    Future<void> Function()? ensureDirectoriesExist,
    Future<String?> Function()? findInstalledModelPath,
  }) : _assetLoader = assetLoader ?? rootBundle.load,
       _destinationPathProvider =
           destinationPathProvider ?? (() => AsrModelPaths.vadModelPath),
       _ensureDirectoriesExist =
           ensureDirectoriesExist ?? AsrModelPaths.ensureDirectoriesExist,
       _findInstalledModelPath =
           findInstalledModelPath ?? (AsrModelPaths.findVadModelPath);

  Future<String?> resolveModelPath() async {
    final existingPath = await _findInstalledModelPath();
    return existingPath ?? ensureInstalled();
  }

  Future<String?> ensureInstalled() async {
    try {
      await _ensureDirectoriesExist();

      final destinationPath = await _destinationPathProvider();
      final targetFile = File(destinationPath);
      final assetBytes = await _loadAssetBytes();

      if (targetFile.existsSync() &&
          await targetFile.length() == assetBytes.length) {
        return destinationPath;
      }

      await targetFile.writeAsBytes(assetBytes, flush: true);
      return destinationPath;
    } catch (_) {
      return _findInstalledModelPath();
    }
  }

  Future<Uint8List> _loadAssetBytes() async {
    final byteData = await _assetLoader(assetPath);

    return byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
  }
}
