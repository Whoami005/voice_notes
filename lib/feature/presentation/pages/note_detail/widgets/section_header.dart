import 'package:flutter/material.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Text(
      title,
      style: AppTypography.overline.copyWith(color: themeColors.textSecondary),
    );
  }
}
