import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class QuickRecordCard extends StatelessWidget {
  final VoidCallback? onTap;

  const QuickRecordCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: themeColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: themeColors.borderPrimary),
        ),
        child: Row(
          children: [
            _MicIcon(),
            AppSpacer.p14,
            Expanded(
              child: _TextContent(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      width: AppSizes.avatarLarge,
      height: AppSizes.avatarLarge,
      decoration: BoxDecoration(
        color: themeColors.accentPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.mic,
        color: themeColors.accentPrimary,
        size: AppSizes.iconLarge,
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрая запись',
          style: textTheme.titleMedium,
        ),
        AppSpacer.p2,
        Text(
          'Запишите заметку без выбора папки',
          style: textTheme.labelMedium?.copyWith(
            color: themeColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
