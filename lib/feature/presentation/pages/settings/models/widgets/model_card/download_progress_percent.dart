part of 'model_card.dart';

class _DownloadProgressPercent extends StatelessWidget {
  final ModelDownloadProgress progress;

  const _DownloadProgressPercent({required this.progress});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final percent = math.max(0, (progress.progress * 100).toInt());

    return Text(
      '$percent%',
      style: AppTypography.caption.copyWith(color: themeColors.textSecondary),
    );
  }
}
