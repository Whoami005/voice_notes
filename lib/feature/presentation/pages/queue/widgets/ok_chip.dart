import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';

class OkChip extends StatelessWidget {
  const OkChip({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: themeColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizes.p12),
      ),
      child: Text(
        'OK',
        style: AppTypography.caption.copyWith(
          color: themeColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
