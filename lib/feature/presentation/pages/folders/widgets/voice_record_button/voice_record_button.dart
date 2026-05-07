import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/common/utils/duration_formatter.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/note_ingestion/note_ingestion_service.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/success_dialog.dart';

part 'animated_voice_button.dart';
part 'ripple_data.dart';
part 'ripple_widget.dart';
part 'timer_badge.dart';
part 'voice_button_badge.dart';
part 'voice_record_button_content.dart';
part 'voice_record_button_styles.dart';
part 'waiting_badge.dart';

class VoiceRecordButton extends StatelessWidget {
  const VoiceRecordButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isAsrReady = context.select((AsrCubit c) => c.state.isReady);

    if (!isAsrReady) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => RecordingCubit(
        recordingService: getIt<AudioRecordingService>(),
        queueController: getIt<TranscriptionQueueController>(),
        noteRepository: getIt<NoteRepository>(),
        playbackController: getIt<AudioPlaybackController>(),
        ingestionService: getIt<NoteIngestionService>(),
      ),
      child: BlocListener<RecordingCubit, RecordingState>(
        listener: _handleStateChange,
        child: const _VoiceRecordButtonContent(),
      ),
    );
  }

  void _handleStateChange(BuildContext context, RecordingState state) {
    switch (state) {
      case RecordingSuccessState(:final text):
        SuccessDialog.showClipboardSuccess(context, text: text);
      case RecordingErrorState(:final failure):
        ErrorDialog.showFromFailure(context, failure);
      default:
        break;
    }
  }
}
