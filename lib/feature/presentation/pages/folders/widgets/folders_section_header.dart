import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';

/// Header widget for folder list section.
///
/// Displays a title with a count badge and optional trailing widget.
class FoldersSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Widget? trailing;

  const FoldersSectionHeader({
    required this.title,
    required this.count,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Row(
      children: [
        Text(
          title,
          style: AppTypography.overline.copyWith(
            color: themeColors.textSecondary,
          ),
        ),
        AppSpacer.p8,
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.p2,
            horizontal: AppSizes.p8,
          ),
          decoration: BoxDecoration(
            color: themeColors.bgTertiary,
            borderRadius: BorderRadius.circular(AppSizes.chipRadius),
          ),
          child: Text(
            '$count',
            style: AppTypography.captionSmall.copyWith(
              color: themeColors.textTertiary,
            ),
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}
