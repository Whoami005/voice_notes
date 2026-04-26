part of 'voice_record_button.dart';

class _WaitingBadge extends StatelessWidget {
  const _WaitingBadge({
    required this.label,
    required this.colors,
    required this.maxWidth,
  });

  final String label;
  final VoiceButtonColors colors;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return _VoiceButtonBadge(
      colors: colors,
      maxWidth: maxWidth,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: colors.timerText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
