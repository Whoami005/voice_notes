import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';

typedef WaveformLoader =
    Future<List<double>?> Function(String trackId, String absolutePath);

Future<List<double>?> extractWaveformFromPath(
  String trackId,
  String absolutePath,
) async {
  final audioFile = File(absolutePath);
  if (!audioFile.existsSync()) return null;

  final waveOutFile = await _createWaveformOutputFile(trackId);
  final completer = Completer<Waveform?>();
  StreamSubscription<WaveformProgress>? sub;

  try {
    sub = JustWaveform.extract(audioInFile: audioFile, waveOutFile: waveOutFile)
        .listen(
          (progress) {
            final waveform = progress.waveform;
            final isNotCompleted = waveform != null && !completer.isCompleted;

            if (isNotCompleted) completer.complete(waveform);
          },
          onError: (_, _) {
            if (!completer.isCompleted) completer.complete(null);
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete(null);
          },
        );

    final waveform = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
    if (waveform == null || waveform.length == 0) return null;

    return sampleNormalizedAmplitudes(
      length: waveform.length,
      readAmplitude: (index) {
        final pixelMax = waveform.getPixelMax(index).abs().toDouble();
        final pixelMin = waveform.getPixelMin(index).abs().toDouble();

        return pixelMax > pixelMin ? pixelMax : pixelMin;
      },
    );
  } finally {
    await sub?.cancel();
    await _deleteWaveformOutputFile(waveOutFile);
  }
}

Future<File> _createWaveformOutputFile(String trackId) async {
  final tempDir = await getTemporaryDirectory();
  return File('${tempDir.path}/waveform_${trackId.hashCode}.wave');
}

Future<void> _deleteWaveformOutputFile(File waveOutFile) async {
  try {
    if (waveOutFile.existsSync()) await waveOutFile.delete();
  } catch (_) {}
}

@visibleForTesting
List<double>? sampleNormalizedAmplitudes({
  required int length,
  required double Function(int index) readAmplitude,
  int sampleCount = 100,
}) {
  if (length == 0) return null;

  final raw = <double>[];
  double maxAmplitude = 0;
  final step = math.max(1, length ~/ sampleCount);

  for (var i = 0; i < length; i += step) {
    final amplitude = readAmplitude(i);

    raw.add(amplitude);
    if (amplitude > maxAmplitude) maxAmplitude = amplitude;
  }

  if (maxAmplitude == 0) return null;

  return <double>[
    for (final amplitude in raw) (amplitude / maxAmplitude).clamp(0.0, 1.0),
  ];
}
