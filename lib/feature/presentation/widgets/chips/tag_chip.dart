import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TagChip({required this.label, super.key, this.onDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final hasDelete = onDelete != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: hasDelete ? AppSizes.p12 : AppSizes.p10,
          vertical: hasDelete ? AppSizes.p6 : AppSizes.p4,
        ),
        decoration: BoxDecoration(
          color: themeColors.accentMuted,
          borderRadius: BorderRadius.circular(AppSizes.chipRadius),
        ),
        child: Row(
          spacing: AppSizes.p4,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$label',
              style: textTheme.labelSmall?.copyWith(
                color: themeColors.accentPrimary,
              ),
            ),
            if (hasDelete)
              GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: themeColors.accentPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
