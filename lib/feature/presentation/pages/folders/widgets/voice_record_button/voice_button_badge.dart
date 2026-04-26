part of 'voice_record_button.dart';

class _VoiceButtonBadge extends StatelessWidget {
  const _VoiceButtonBadge({
    required this.colors,
    required this.child,
    this.maxWidth,
  });

  final VoiceButtonColors colors;
  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final badge = ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.blurModerate,
          sigmaY: AppSizes.blurModerate,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p6,
          ),
          decoration: BoxDecoration(
            color: colors.timerBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: child,
        ),
      ),
    );

    final width = maxWidth;
    if (width == null) return badge;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: badge,
    );
  }
}
