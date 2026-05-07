import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class NoteInfoChip extends StatelessWidget {
  final String text;

  const NoteInfoChip({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: themeColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: Text(text, style: context.textTheme.labelSmall),
    );
  }
}
