import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class DateSeparator extends StatelessWidget {
  final String date;

  const DateSeparator({required this.date, super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.p16),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p14,
          vertical: AppSizes.p6,
        ),
        decoration: BoxDecoration(
          color: themeColors.bgTertiary,
          borderRadius: BorderRadius.circular(AppSizes.chipRadius),
        ),
        child: Text(
          date,
          style: textTheme.labelSmall?.copyWith(
            color: themeColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
