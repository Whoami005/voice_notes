import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool isEnabled;

  const SettingsRow({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final opacity = isEnabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: AppSizes.iconMedium,
                    color: themeColors.textSecondary,
                  ),
                  AppSpacer.p14,
                  Expanded(
                    child: Column(
                      spacing: AppSizes.p2,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.body.copyWith(
                            color: themeColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTypography.caption.copyWith(
                              color: themeColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AppSpacer.p2,
                  ?trailing,
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                thickness: 1,
                indent: AppSizes.p16 + AppSizes.iconMedium + AppSizes.p14,
                endIndent: 0,
                color: themeColors.borderPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsToggle({required this.value, super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return SizedBox(
      width: AppSizes.toggleWidth,
      height: AppSizes.toggleHeight,
      child: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: themeColors.accentPrimary,
        activeTrackColor: themeColors.accentPrimary.withValues(alpha: 0.5),
      ),
    );
  }
}

class SettingsChevron extends StatelessWidget {
  final String? value;

  const SettingsChevron({super.key, this.value});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Row(
      spacing: 4,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value != null)
          Text(
            value!,
            style: AppTypography.body.copyWith(color: themeColors.textTertiary),
          ),
        Icon(
          Icons.chevron_right,
          size: AppSizes.iconMedium,
          color: themeColors.textTertiary,
        ),
      ],
    );
  }
}
