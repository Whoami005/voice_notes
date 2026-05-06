import 'package:flutter/material.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_nav_destination.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        border: Border(top: BorderSide(color: themeColors.borderPrimary)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: [
          for (final destination in AppNavDestination.items)
            BottomNavigationBarItem(
              icon: Icon(destination.icon),
              activeIcon: Icon(destination.selectedIcon),
              label: destination.labelBuilder(l10n),
            ),
        ],
      ),
    );
  }
}
