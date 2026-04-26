part of 'model_card.dart';

class _DownloadProgressPanel extends StatelessWidget {
  final ModelDownloadProgress progress;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const _DownloadProgressPanel({
    required this.progress,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  bool get _showActionButtons =>
      progress.status.isDownloading ||
      progress.status.isPaused ||
      progress.status.isQueued;

  @override
  Widget build(BuildContext context) {
    final status = progress.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _DownloadStatusText(progress: progress)),
            if (status.isDownloading || status.isPaused)
              _DownloadProgressPercent(progress: progress),
          ],
        ),
        AppSpacer.p4,
        _DownloadProgressIndicator(progress: progress),
        if (_showActionButtons) ...[
          AppSpacer.p12,
          _DownloadActionButtons(
            progress: progress,
            onPause: onPause,
            onResume: onResume,
            onCancel: onCancel,
          ),
        ],
      ],
    );
  }
}
