part of 'voice_record_button.dart';

class _AnimatedVoiceButton extends StatelessWidget {
  const _AnimatedVoiceButton({
    required this.colors,
    required this.isDarkMode,
    required this.isRecording,
    required this.isTranscribing,
    required this.gradientAnimation,
    this.onTap,
  });

  final VoiceButtonColors colors;
  final bool isDarkMode;
  final bool isRecording;
  final bool isTranscribing;
  final Animation<double> gradientAnimation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: gradientAnimation,
        builder: (context, child) {
          return Container(
            width: _VoiceRecordButtonStyles.buttonSize,
            height: _VoiceRecordButtonStyles.buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _buildGradient(),
              border: Border.all(
                color: isRecording ? colors.borderActive : colors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: isDarkMode
                      ? _VoiceRecordButtonStyles.darkShadowBlur
                      : _VoiceRecordButtonStyles.lightShadowBlur,
                  offset: _VoiceRecordButtonStyles.shadowOffset,
                ),
                if (isRecording)
                  BoxShadow(
                    color: colors.glow,
                    blurRadius: _VoiceRecordButtonStyles.glowBlurRadius,
                  ),
              ],
            ),
            child: Center(
              child: isTranscribing
                  ? SizedBox(
                      width: AppSizes.iconLarge,
                      height: AppSizes.iconLarge,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.strokeMedium,
                        color: colors.icon,
                      ),
                    )
                  : AnimatedScale(
                      scale: isRecording
                          ? _VoiceRecordButtonStyles.activeIconScale
                          : 1.0,
                      duration:
                          _VoiceRecordButtonStyles.activeIconScaleDuration,
                      child: Icon(
                        Icons.mic,
                        color: colors.icon,
                        size: AppSizes.iconMedium,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _buildGradient() {
    if (!isRecording) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.idleGradient,
      );
    }

    final shift = gradientAnimation.value;
    return LinearGradient(
      begin: Alignment(-1.0 + shift, -1.0 + shift),
      end: Alignment(1.0 + shift, 1.0 + shift),
      colors: colors.activeGradient,
      stops: const [0.0, 0.33, 0.66, 1.0],
    );
  }
}
