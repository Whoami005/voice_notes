import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class NoteActionsSection extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onRetranscribe;
  final VoidCallback onDelete;

  const NoteActionsSection({
    required this.onCopy,
    required this.onDelete,
    this.onShare,
    this.onRetranscribe,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Column(
      spacing: AppSizes.p8,
      children: [
        _ActionButton(
          icon: Icons.copy_outlined,
          label: 'Копировать текст',
          onTap: onCopy,
        ),
        // _ActionButton(
        //   icon: Icons.share_outlined,
        //   label: 'Поделиться',
        //   onTap: onShare,
        // ),
        // _ActionButton(
        //   icon: Icons.refresh,
        //   label: 'Перетранскрибировать',
        //   onTap: onRetranscribe,
        // ),
        _ActionButton(
          icon: Icons.delete_outline,
          label: 'Удалить заметку',
          color: themeColors.error,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final buttonColor = color ?? themeColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: themeColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: themeColors.borderPrimary),
        ),
        child: Row(
          spacing: AppSizes.p12,
          children: [
            Icon(icon, size: AppSizes.iconMedium, color: buttonColor),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: buttonColor),
            ),
          ],
        ),
      ),
    );
  }
}
