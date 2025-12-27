import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // =>=>=>=>=>=>=>=>=>=>=>=> DARK THEME =>=>=>=>=>=>=>=>=>=>=>=>
  static const dark = _DarkColors();

  // =>=>=>=>=>=>=>=>=>=>=>=> LIGHT THEME =>=>=>=>=>=>=>=>=>=>=>=>
  static const light = _LightColors();

  // =>=>=>=>=>=>=>=>=>=>=>=> SHARED =>=>=>=>=>=>=>=>=>=>=>=>
  static const folderColors = [
    Color(0xFFF59E0B), // amber
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // purple
    Color(0xFFEF4444), // red
    Color(0xFF06B6D4), // cyan
    Color(0xFF84CC16), // lime
  ];
}

class _DarkColors {
  const _DarkColors();

  // Backgrounds
  Color get bgPrimary => const Color(0xFF0A0A0B);

  Color get bgSecondary => const Color(0xFF141416);

  Color get bgTertiary => const Color(0xFF1C1C1F);

  Color get bgElevated => const Color(0xFF242428);

  // Text
  Color get textPrimary => const Color(0xFFFFFFFF);

  Color get textSecondary => const Color(0xFFA1A1AA);

  Color get textTertiary => const Color(0xFF71717A);

  Color get textInverse => const Color(0xFF0A0A0B);

  // Accent
  Color get accentPrimary => const Color(0xFFF59E0B);

  Color get accentSecondary => const Color(0xFFFBBF24);

  Color get accentMuted => const Color(0xFFF59E0B).withValues(alpha: 0.15);

  Color get accentGlow => const Color(0xFFF59E0B).withValues(alpha: 0.30);

  // Borders
  Color get borderPrimary => const Color(0xFF27272A);

  Color get borderSecondary => const Color(0xFF3F3F46);

  // Status
  Color get success => const Color(0xFF22C55E);

  Color get error => const Color(0xFFEF4444);

  Color get warning => const Color(0xFFF59E0B);

  Color get info => const Color(0xFF3B82F6);

  // Recording
  Color get recordingBg => const Color(0xFF7F1D1D);

  Color get recordingPulse => const Color(0xFFEF4444);

  // Overlay
  Color get overlay => Colors.black.withValues(alpha: 0.6);
}

class _LightColors {
  const _LightColors();

  // Backgrounds
  Color get bgPrimary => const Color(0xFFFAFAF9);

  Color get bgSecondary => const Color(0xFFFFFFFF);

  Color get bgTertiary => const Color(0xFFF5F5F4);

  Color get bgElevated => const Color(0xFFFFFFFF);

  // Text
  Color get textPrimary => const Color(0xFF1C1917);

  Color get textSecondary => const Color(0xFF57534E);

  Color get textTertiary => const Color(0xFFA8A29E);

  Color get textInverse => const Color(0xFFFFFFFF);

  // Accent
  Color get accentPrimary => const Color(0xFFD97706);

  Color get accentSecondary => const Color(0xFFF59E0B);

  Color get accentMuted => const Color(0xFFD97706).withValues(alpha: 0.10);

  Color get accentGlow => const Color(0xFFD97706).withValues(alpha: 0.20);

  // Borders
  Color get borderPrimary => const Color(0xFFE7E5E4);

  Color get borderSecondary => const Color(0xFFD6D3D1);

  // Status
  Color get success => const Color(0xFF16A34A);

  Color get error => const Color(0xFFDC2626);

  Color get warning => const Color(0xFFD97706);

  Color get info => const Color(0xFF2563EB);

  // Recording
  Color get recordingBg => const Color(0xFFFEF2F2);

  Color get recordingPulse => const Color(0xFFEF4444);

  // Overlay
  Color get overlay => Colors.black.withValues(alpha: 0.4);
}
