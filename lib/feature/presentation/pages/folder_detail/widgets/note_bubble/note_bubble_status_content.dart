part of 'note_bubble.dart';

class _StatusContent extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const _StatusContent({
    required this.note,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (note.isCompleted) {
      final textTheme = context.textTheme;

      return Text(
        note.text,
        style: textTheme.bodyMedium?.copyWith(height: 1.5),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      );
    }

    final themeColors = context.themeColors;
    final l10n = context.l10n;

    final cancel = onCancel;
    final cancelAction = cancel == null
        ? null
        : _StatusAction(
            icon: Icons.close,
            label: l10n.noteActionCancel,
            color: themeColors.textSecondary,
            onPressed: cancel,
          );

    if (note.isQueued) {
      return _StatusLine(
        icon: Icons.schedule_outlined,
        label: l10n.noteStatusQueued,
        color: themeColors.textSecondary,
        italic: true,
        action: cancelAction,
      );
    }

    if (note.isTranscribing) {
      return BlocSelector<
        TranscriptionQueueCubit,
        TranscriptionQueueState,
        _TranscribingViewData
      >(
        selector: (state) =>
            _TranscribingViewData.fromSnapshot(state.snapshot, note.uuid),
        builder: (context, data) {
          if (data.supportsInteractiveProgress) {
            return _InteractiveTranscribingRow(
              progress: data.progress,
              previewText: data.previewText,
              fallbackLabel: _transcribingLabel(context),
              cancelAction: data.supportsCancellation ? cancelAction : null,
            );
          }

          return _StatusLine(
            showSpinner: true,
            label: _transcribingLabel(context),
            color: themeColors.textSecondary,
            italic: true,
          );
        },
      );
    }

    final retry = onRetry;
    final retryAction = retry == null
        ? null
        : _StatusAction(
            icon: Icons.refresh,
            label: l10n.noteActionRetry,
            color: themeColors.accentPrimary,
            onPressed: retry,
          );

    if (note.isCancelled) {
      return _StatusLine(
        icon: Icons.block_outlined,
        label: l10n.noteStatusCancelled,
        color: themeColors.textTertiary,
        action: retryAction,
      );
    }

    final reason = note.failureReason ?? TranscriptionFailureReason.unknown;
    return _StatusLine(
      icon: Icons.error_outline,
      label: reason.title(l10n),
      color: themeColors.error,
      action: reason.isPermanent ? null : retryAction,
    );
  }

  String _transcribingLabel(BuildContext context) {
    final l10n = context.l10n;
    final asrState = context.read<AsrCubit>().state;
    final modelType = asrState.model?.modelType;
    if (modelType == null) return l10n.noteStatusTranscribing;

    final eta = AsrRtfEstimates.estimate(
      note.origin.sourceDurationOrZero,
      modelId: asrState.model?.uuid,
      modelType: modelType,
    );
    return l10n.noteStatusTranscribingEta(eta.inSeconds);
  }
}
