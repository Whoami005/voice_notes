import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class AppFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? heroTag;

  const AppFab({
    required this.icon,
    required this.onPressed,
    super.key,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.fabRadius),
        boxShadow: [
          BoxShadow(
            color: themeColors.accentGlow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        child: Icon(icon, size: AppSizes.iconLarge),
      ),
    );
  }
}
