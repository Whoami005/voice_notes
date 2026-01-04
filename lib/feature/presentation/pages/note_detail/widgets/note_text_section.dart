import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class NoteTextSection extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  final bool isEditing;

  const NoteTextSection({
    required this.text,
    required this.controller,
    required this.isEditing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return TextField(
      readOnly: !isEditing,
      controller: controller,
      maxLines: null,
      minLines: 4,
      style: textTheme.bodyMedium?.copyWith(
        color: themeColors.textPrimary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(AppSizes.cardPadding),
        hintText: 'Введите текст заметки...',
        filled: true,
        fillColor: themeColors.bgSecondary,
        border: OutlineInputBorder(
          gapPadding: 1,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          borderSide: BorderSide(color: themeColors.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          gapPadding: 1,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          borderSide: BorderSide(color: themeColors.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          gapPadding: 1,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          borderSide: BorderSide(color: themeColors.accentPrimary),
        ),
      ),
    );
  }
}
