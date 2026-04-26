part of 'model_card.dart';

class _DownloadProgressIndicator extends StatelessWidget {
  final ModelDownloadProgress progress;

  const _DownloadProgressIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final status = progress.status;
    final isIndeterminate =
        status.isPreparing || status.isQueued || status.isExtracting;

    final color = switch (status) {
      DownloadStatus.paused => themeColors.warning,
      DownloadStatus.failed => themeColors.error,
      DownloadStatus.cancelled => themeColors.textTertiary,
      _ => themeColors.accentPrimary,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.p4),
      child: LinearProgressIndicator(
        value: isIndeterminate ? null : progress.progress,
        minHeight: AppSizes.p4,
        backgroundColor: themeColors.bgTertiary,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
