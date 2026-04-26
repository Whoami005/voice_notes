part of 'model_card.dart';

class _DownloadStatusText extends StatelessWidget {
  final ModelDownloadProgress progress;

  const _DownloadStatusText({required this.progress});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;
    final status = progress.status;

    final text = status.isFailed
        ? progress.errorMessage ?? l10n.modelStatusError
        : status.statusTitle(l10n);

    final color = switch (status) {
      DownloadStatus.paused => themeColors.warning,
      DownloadStatus.failed => themeColors.error,
      DownloadStatus.cancelled => themeColors.textTertiary,
      _ => themeColors.textSecondary,
    };

    return Text(
      text,
      style: AppTypography.caption.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
