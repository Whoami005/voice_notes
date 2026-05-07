import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class NoteInfoCard extends StatelessWidget {
  final Widget child;

  const NoteInfoCard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: child,
    );
  }
}
