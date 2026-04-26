part of 'model_card.dart';

class _DownloadActionButtons extends StatelessWidget {
  final ModelDownloadProgress progress;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const _DownloadActionButtons({
    required this.progress,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;
    final isPaused = progress.status.isPaused;

    return Row(
      spacing: AppSizes.p8,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPaused ? onResume : onPause,
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              size: AppSizes.iconMedium,
            ),
            label: Text(
              isPaused ? l10n.modelActionResume : l10n.modelActionPause,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: themeColors.textSecondary,
              side: BorderSide(color: themeColors.borderPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onCancel,
          icon: Icon(
            Icons.close,
            color: themeColors.error,
            size: AppSizes.iconLarge,
          ),
          style: IconButton.styleFrom(
            backgroundColor: themeColors.error.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            ),
          ),
        ),
      ],
    );
  }
}
