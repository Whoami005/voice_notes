import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: themeColors.textTertiary,
            ),
          ),
        ),
        AppSpacer.p8,
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          decoration: BoxDecoration(
            color: themeColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: themeColors.borderPrimary),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
