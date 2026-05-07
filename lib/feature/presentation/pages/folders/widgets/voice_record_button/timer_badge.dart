part of 'voice_record_button.dart';

class _TimerBadge extends StatelessWidget {
  const _TimerBadge({required this.duration, required this.colors});

  final Duration duration;
  final VoiceButtonColors colors;

  @override
  Widget build(BuildContext context) {
    return _VoiceButtonBadge(
      colors: colors,
      child: Text(
        DurationFormatter.compact(duration),
        style: AppTypography.caption.copyWith(
          color: colors.timerText,
          fontWeight: FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
