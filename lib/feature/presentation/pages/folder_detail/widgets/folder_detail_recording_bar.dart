import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/routes/folders_route_presentation.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/folder_detail_adaptive.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/recording_input/recording_input.dart';

/// Recording input bar for folder detail screen.
///
/// Запись доступна всегда — очередь транскрибации сама подождёт готовности
/// ASR-модели (см. `TranscriptionQueueCubit`). Статус модели показывается
/// отдельно через `AsrStatusBanner`.
class FolderDetailRecordingBar extends StatelessWidget {
  const FolderDetailRecordingBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isWorkspace = FoldersRoutePresentation.fromContext(
      context,
    ).isWorkspaceActive;

    return BlocConsumer<RecordingCubit, RecordingState>(
      listener: _handleRecordingStateChange,
      builder: (context, state) {
        final cubit = context.read<RecordingCubit>();

        return Padding(
          padding: EdgeInsets.only(
            left: isWorkspace ? AppSizes.p0 : AppSizes.screenPadding,
            right: isWorkspace ? AppSizes.p0 : AppSizes.screenPadding,
            bottom: isWorkspace
                ? AppSizes.p0
                : context.bottomInset +
                      context.bottomKeyboardInsets +
                      AppSizes.p16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWorkspace
                  ? double.infinity
                  : FolderDetailAdaptive.recordingBarMaxWidth,
            ),
            child: RecordingInput(
              state: state.uiState,
              useWorkspaceLayout: isWorkspace,
              recordingDuration: state.durationOrNull ?? Duration.zero,
              amplitudes: switch (state) {
                RecordingActiveState(:final amplitudes) => amplitudes,
                _ => const [],
              },
              onStartRecording: cubit.startRecording,
              onStopRecording: cubit.stopRecording,
              onCancelRecording: cubit.cancelRecording,
              onTextSubmit: cubit.createTextNote,
            ),
          ),
        );
      },
    );
  }

  void _handleRecordingStateChange(BuildContext context, RecordingState state) {
    if (state is RecordingErrorState) _showErrorToast(context, state);
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
