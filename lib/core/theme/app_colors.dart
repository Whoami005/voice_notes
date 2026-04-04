import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // =>=>=>=>=>=>=>=>=>=>=>=> DARK THEME =>=>=>=>=>=>=>=>=>=>=>=>
  static const dark = _DarkColors();

  // =>=>=>=>=>=>=>=>=>=>=>=> LIGHT THEME =>=>=>=>=>=>=>=>=>=>=>=>
  static const light = _LightColors();

  // =>=>=>=>=>=>=>=>=>=>=>=> SHARED =>=>=>=>=>=>=>=>=>=>=>=>
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

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

class VoiceButtonColors {
  final List<Color> idleGradient;
  final List<Color> activeGradient;
  final Color border;
  final Color borderActive;
  final Color icon;
  final Color shadow;
  final Color glow;
  final Color ripple;
  final Color timerBg;
  final Color timerText;

  const VoiceButtonColors({
    required this.idleGradient,
    required this.activeGradient,
    required this.border,
    required this.borderActive,
    required this.icon,
    required this.shadow,
    required this.glow,
    required this.ripple,
    required this.timerBg,
    required this.timerText,
  });
}

class _DarkColors {
  const _DarkColors();

  // ── Backgrounds ──────────────────────────────────────────
  /// Основной фон страницы
  Color get bgPrimary => const Color(0xFF191919);

  /// Вторичный фон — sidebar, карточки
  Color get bgSecondary => const Color(0xFF202020);

  /// Третичный фон — инпуты, серый блок
  Color get bgTertiary => const Color(0xFF252525);

  /// Приподнятые поверхности — попапы, диалоги, dropdown
  Color get bgElevated => const Color(0xFF2F2F2F);

  // ── Text ─────────────────────────────────────────────────
  /// Основной текст
  Color get textPrimary => const Color(0xFFD4D4D4);

  /// Вторичный текст — подписи, метаданные
  Color get textSecondary => const Color(0xFF9B9B9B);

  /// Третичный текст — placeholder, hint
  Color get textTertiary => const Color(0xFF5A5A5A);

  /// Инвертированный текст — на акцентных кнопках
  Color get textInverse => const Color(0xFF191919);

  // ── Accent ───────────────────────────────────────────────
  /// Основной акцент — ссылки, CTA, активные элементы
  Color get accentPrimary => const Color(0xFFF59E0B);

  /// Вторичный акцент — outlined кнопки, иконки
  Color get accentSecondary => const Color(0xFFFBBF24);

  /// Приглушённый акцент — фон чипов, выделение
  Color get accentMuted => const Color(0xFFF59E0B).withValues(alpha: 0.15);

  /// Свечение — focus ring, soft glow
  Color get accentGlow => const Color(0xFFF59E0B).withValues(alpha: 0.30);

  // ── Borders ──────────────────────────────────────────────
  /// Основная граница — разделители, карточки
  Color get borderPrimary => const Color(0xFF2F2F2F);

  /// Вторичная граница — hover, более заметная
  Color get borderSecondary => const Color(0xFF3A3A3A);

  // ── Status ───────────────────────────────────────────────
  /// (green text dark)
  Color get success => const Color(0xFF4F9768);

  /// (red icon dark)
  Color get error => const Color(0xFFCD4945);

  /// (yellow text dark)
  Color get warning => const Color(0xFFC19138);

  /// (blue icon dark)
  Color get info => const Color(0xFF2E7CD1);

  // ── Recording ────────────────────────────────────────────
  /// (red bg dark)
  Color get recordingBg => const Color(0xFF332523);

  Color get recordingPulse => const Color(0xFFCD4945);

  // ── Overlay ──────────────────────────────────────────────
  Color get overlay => AppColors.black.withValues(alpha: 0.6);

  // ── Voice Record Button ────────────────────────────────────
  VoiceButtonColors get voiceButton => VoiceButtonColors(
    idleGradient: const [
      Color(0xFF3A3A3C),
      Color(0xFF2C2C2E),
      Color(0xFF1C1C1E),
    ],
    activeGradient: const [
      Color(0xFF5A5A5C),
      Color(0xFF4A4A4C),
      Color(0xFF3A3A3C),
      Color(0xFF5A5A5C),
    ],
    border: const Color(0xFFFFFFFF).withValues(alpha: 0.15),
    borderActive: const Color(0xFFFFFFFF).withValues(alpha: 0.3),
    icon: const Color(0xFFFFFFFF),
    shadow: AppColors.black.withValues(alpha: 0.4),
    glow: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
    ripple: const Color(0xFFFFFFFF).withValues(alpha: 0.15),
    timerBg: AppColors.black.withValues(alpha: 0.75),
    timerText: const Color(0xFFFFFFFF),
  );
}

class _LightColors {
  const _LightColors();

  // Backgrounds
  Color get bgPrimary => const Color(0xFFFAFAF9);

  Color get bgSecondary => const Color(0xFFFFFFFF);

  Color get bgTertiary => const Color(0xFFF5F5F4);

  Color get bgElevated => const Color(0xFFFEFDFB);

  // Text
  Color get textPrimary => const Color(0xFF1C1917);

  Color get textSecondary => const Color(0xFF57534E);

  Color get textTertiary => const Color(0xFFA8A29E);

  Color get textInverse => const Color(0xFFFFFFFF);

  // Accent
  Color get accentPrimary => const Color(0xFF6366F1);

  Color get accentSecondary => const Color(0xFF818CF8);

  Color get accentMuted => const Color(0xFFEEF2FF);

  Color get accentGlow => const Color(0xFFA5B4FC);

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
  Color get overlay => AppColors.black.withValues(alpha: 0.4);

  // ── Voice Record Button ────────────────────────────────────
  VoiceButtonColors get voiceButton => VoiceButtonColors(
    idleGradient: const [
      Color(0xFF818CF8),
      Color(0xFF6366F1),
      Color(0xFF4F46E5),
    ],
    activeGradient: const [
      Color(0xFF818CF8),
      Color(0xFF6366F1),
      Color(0xFF4F46E5),
      Color(0xFF818CF8),
    ],
    border: const Color(0xFF6366F1).withValues(alpha: 0.3),
    borderActive: const Color(0xFF6366F1).withValues(alpha: 0.4),
    icon: const Color(0xFFFFFFFF),
    shadow: AppColors.black.withValues(alpha: 0.08),
    glow: const Color(0xFF6366F1).withValues(alpha: 0.2),
    ripple: const Color(0xFF6366F1).withValues(alpha: 0.2),
    timerBg: const Color(0xFFFFFFFF).withValues(alpha: 0.85),
    timerText: const Color(0xFF312E81),
  );
}
