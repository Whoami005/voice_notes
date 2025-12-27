import 'package:flutter/material.dart';
import 'package:voice_notes/core/theme/app_colors.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentMuted;
  final Color accentGlow;
  final Color borderPrimary;
  final Color borderSecondary;
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  final Color recordingBg;
  final Color recordingPulse;
  final Color overlay;

  const AppColorsExtension({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentMuted,
    required this.accentGlow,
    required this.borderPrimary,
    required this.borderSecondary,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.recordingBg,
    required this.recordingPulse,
    required this.overlay,
  });

  factory AppColorsExtension.dark() {
    const c = AppColors.dark;

    return AppColorsExtension(
      bgPrimary: c.bgPrimary,
      bgSecondary: c.bgSecondary,
      bgTertiary: c.bgTertiary,
      bgElevated: c.bgElevated,
      textPrimary: c.textPrimary,
      textSecondary: c.textSecondary,
      textTertiary: c.textTertiary,
      textInverse: c.textInverse,
      accentPrimary: c.accentPrimary,
      accentSecondary: c.accentSecondary,
      accentMuted: c.accentMuted,
      accentGlow: c.accentGlow,
      borderPrimary: c.borderPrimary,
      borderSecondary: c.borderSecondary,
      success: c.success,
      error: c.error,
      warning: c.warning,
      info: c.info,
      recordingBg: c.recordingBg,
      recordingPulse: c.recordingPulse,
      overlay: c.overlay,
    );
  }

  factory AppColorsExtension.light() {
    const c = AppColors.light;

    return AppColorsExtension(
      bgPrimary: c.bgPrimary,
      bgSecondary: c.bgSecondary,
      bgTertiary: c.bgTertiary,
      bgElevated: c.bgElevated,
      textPrimary: c.textPrimary,
      textSecondary: c.textSecondary,
      textTertiary: c.textTertiary,
      textInverse: c.textInverse,
      accentPrimary: c.accentPrimary,
      accentSecondary: c.accentSecondary,
      accentMuted: c.accentMuted,
      accentGlow: c.accentGlow,
      borderPrimary: c.borderPrimary,
      borderSecondary: c.borderSecondary,
      success: c.success,
      error: c.error,
      warning: c.warning,
      info: c.info,
      recordingBg: c.recordingBg,
      recordingPulse: c.recordingPulse,
      overlay: c.overlay,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgTertiary,
    Color? bgElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? accentMuted,
    Color? accentGlow,
    Color? borderPrimary,
    Color? borderSecondary,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? recordingBg,
    Color? recordingPulse,
    Color? overlay,
  }) {
    return AppColorsExtension(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgTertiary: bgTertiary ?? this.bgTertiary,
      bgElevated: bgElevated ?? this.bgElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentMuted: accentMuted ?? this.accentMuted,
      accentGlow: accentGlow ?? this.accentGlow,
      borderPrimary: borderPrimary ?? this.borderPrimary,
      borderSecondary: borderSecondary ?? this.borderSecondary,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      recordingBg: recordingBg ?? this.recordingBg,
      recordingPulse: recordingPulse ?? this.recordingPulse,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgTertiary: Color.lerp(bgTertiary, other.bgTertiary, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      borderPrimary: Color.lerp(borderPrimary, other.borderPrimary, t)!,
      borderSecondary: Color.lerp(borderSecondary, other.borderSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      recordingBg: Color.lerp(recordingBg, other.recordingBg, t)!,
      recordingPulse: Color.lerp(recordingPulse, other.recordingPulse, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}
