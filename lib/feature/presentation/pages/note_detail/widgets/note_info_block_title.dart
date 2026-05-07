import 'package:flutter/material.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class NoteInfoBlockTitle extends StatelessWidget {
  final String title;

  const NoteInfoBlockTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Text(
      title.toUpperCase(),
      style: context.textTheme.labelSmall?.copyWith(
        color: themeColors.textSecondary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
