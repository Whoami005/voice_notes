import 'dart:async';

import 'package:voice_notes/core/packages/asr/asr_result.dart';

final class PriorityTranscriptionTask {
  final String filePath;
  final Duration audioDurationHint;
  final void Function()? onStarted;
  final Completer<AsrResult> completer;

  const PriorityTranscriptionTask({
    required this.filePath,
    required this.audioDurationHint,
    required this.onStarted,
    required this.completer,
  });

  Future<AsrResult> get future => completer.future;

  void markStarted() {
    onStarted?.call();
  }

  void complete(AsrResult result) {
    if (!completer.isCompleted) completer.complete(result);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (!completer.isCompleted) {
      completer.completeError(error, stackTrace);
    }
  }
}
