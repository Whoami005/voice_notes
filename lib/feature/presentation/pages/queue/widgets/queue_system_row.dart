import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';

class QueueSystemRow extends StatelessWidget {
  final IconData icon;
  final Color iconTone;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final Widget trailing;

  const QueueSystemRow({
    required this.icon,
    required this.iconTone,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Row(
      spacing: AppSizes.p12,
      children: [
        Container(
          width: AppSizes.p32,
          height: AppSizes.p32,
          decoration: BoxDecoration(
            color: iconTone.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppSizes.p8),
          ),
          child: Icon(icon, size: AppSizes.iconMedium, color: iconTone),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacer.p2,
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: subtitleColor),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
