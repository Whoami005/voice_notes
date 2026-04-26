import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/feature/domain/enums/recording_state.dart';

part 'cancel_x_button.dart';
part 'ghost_icon_button.dart';
part 'idle_action_circle.dart';
part 'idle_state.dart';
part 'live_waveform.dart';
part 'pulse_dot.dart';
part 'recording_state.dart';
part 'send_circle.dart';

/// Универсальный input-бар записи: переключается между idle и recording.
///
/// Внутренние виджеты — приватные `part of` файлы в этой же директории.
/// Снаружи импортируется только сам `RecordingInput`.
class RecordingInput extends StatelessWidget {
  final RecordingInputState state;
  final Duration recordingDuration;
  final List<double> amplitudes;
  final String? transcribingText;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onCancelRecording;
  final VoidCallback? onUploadFile;

  final TextEditingController? textController;
  final ValueChanged<String>? onTextSubmit;

  const RecordingInput({
    required this.state,
    this.recordingDuration = Duration.zero,
    this.amplitudes = const [],
    this.transcribingText,
    this.onStartRecording,
    this.onStopRecording,
    this.onCancelRecording,
    this.onUploadFile,
    this.textController,
    this.onTextSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      RecordingInputState.idle => _IdleState(
        onStartRecording: onStartRecording,
        onUploadFile: onUploadFile,
        textController: textController,
        onTextSubmit: onTextSubmit,
      ),
      RecordingInputState.recording => _RecordingState(
        duration: recordingDuration,
        amplitudes: amplitudes,
        onStopRecording: onStopRecording,
        onCancelRecording: onCancelRecording,
      ),
    };
  }
}
