part of 'voice_record_button.dart';

abstract final class _VoiceRecordButtonStyles {
  static const double buttonSize = 60;
  static const int maxRipples = 4;
  static const Duration pulseDuration = Duration(milliseconds: 1500);
  static const Duration gradientDuration = Duration(milliseconds: 2000);
  static const Duration rippleSpawnInterval = Duration(milliseconds: 600);
  static const Duration rippleDuration = Duration(milliseconds: 1800);
  static const double pulseScale = 1.05;
  static const double activeIconScale = 1.1;
  static const Duration activeIconScaleDuration = Duration(milliseconds: 200);
  static const double darkShadowBlur = AppSizes.blurXXL;
  static const double lightShadowBlur = AppSizes.blurLarge;
  static const double glowBlurRadius = AppSizes.blurXL;
  static const Offset shadowOffset = Offset(0, AppSizes.p8);
  static const double timerBadgeOffset = AppSizes.p10;
  static const double waitingBadgeMaxWidth = 240;
  static const double waitingBadgeScreenPadding = AppSizes.p16;
  static const double rippleExpansion = 80;
}
