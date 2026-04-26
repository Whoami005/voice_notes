part of 'voice_record_button.dart';

class _RippleWidget extends StatelessWidget {
  const _RippleWidget({required this.animation, required this.colors});

  final Animation<double> animation;
  final VoiceButtonColors colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final size =
            _VoiceRecordButtonStyles.buttonSize +
            (_VoiceRecordButtonStyles.rippleExpansion * animation.value);

        return Opacity(
          opacity: 1.0 - animation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [colors.ripple, AppColors.transparent],
              ),
            ),
          ),
        );
      },
    );
  }
}
