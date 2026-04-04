import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

/// Кнопка "+ Новая" для создания папки
///
/// Стиль: полупрозрачный фон, акцентный цвет для иконки и текста.
class NewFolderButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const NewFolderButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: themeColors.accentMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          spacing: AppSizes.p4,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: themeColors.accentPrimary),
            Text(
              context.l10n.foldersNewButton,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: themeColors.accentPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
