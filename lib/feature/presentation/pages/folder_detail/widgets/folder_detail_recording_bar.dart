import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/recording_input.dart';

/// Recording input bar for folder detail screen.
///
/// Wraps RecordingInput with BlocConsumer to handle recording state
/// and display success/error toasts.
class FolderDetailRecordingBar extends StatelessWidget {
  const FolderDetailRecordingBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecordingCubit, RecordingState>(
      listener: _handleRecordingStateChange,
      builder: (context, state) {
        final cubit = context.read<RecordingCubit>();

        return Padding(
          padding: EdgeInsets.only(
            left: AppSizes.screenPadding,
            right: AppSizes.screenPadding,
            bottom:
                context.bottomInset +
                context.bottomKeyboardInsets +
                AppSizes.p16,
          ),
          child: RecordingInput(
            state: state.uiState,
            recordingDuration: state.durationOrNull ?? Duration.zero,
            transcribingText: state is RecordingTranscribingState
                ? state.partialText
                : null,
            onStartRecording: cubit.startRecording,
            onStopRecording: cubit.stopRecording,
            onCancelRecording: cubit.cancelRecording,
            onUploadFile: _onUploadFile,
            onTextSubmit: cubit.createTextNote,
          ),
        );
      },
    );
  }

  void _onUploadFile() {
    // TODO: Open file picker
  }

  void _handleRecordingStateChange(BuildContext context, RecordingState state) {
    if (state is RecordingSuccessState) {
      _showSuccessToast(context, state);
    } else if (state is RecordingErrorState) {
      _showErrorToast(context, state);
    }
  }

  void _showSuccessToast(BuildContext context, RecordingSuccessState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Заметка создана: ${state.text}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorToast(BuildContext context, RecordingErrorState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.themeColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
