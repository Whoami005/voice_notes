import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_nav_destination.dart';

class AppNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavigationRail({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        border: Border(right: BorderSide(color: themeColors.borderPrimary)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
        child: NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          backgroundColor: themeColors.bgSecondary,
          labelType: NavigationRailLabelType.all,
          destinations: [
            for (final destination in AppNavDestination.items)
              NavigationRailDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: Text(destination.labelBuilder(l10n)),
              ),
          ],
        ),
      ),
    );
  }
}
