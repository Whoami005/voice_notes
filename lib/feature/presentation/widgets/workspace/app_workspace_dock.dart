import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/main_branch_navigation.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_nav_destination.dart';

/// Переключает главные разделы внутри workspace.
class AppWorkspaceDock extends StatelessWidget {
  final AppMainBranch currentBranch;

  const AppWorkspaceDock({required this.currentBranch, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    return SizedBox(
      height: AppSizes.workspaceDockHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: themeColors.workspacePane,
          border: Border(
            top: BorderSide(color: themeColors.workspaceBorderSoft),
          ),
        ),
        child: Row(
          children: [
            for (var index = 0; index < AppNavDestination.items.length; index++)
              Expanded(
                child: _DockDestination(
                  destination: AppNavDestination.items[index],
                  label: AppNavDestination.items[index].labelBuilder(l10n),
                  isSelected: currentBranch.branchIndex == index,
                  onTap: () =>
                      context.goMainBranch(AppMainBranch.fromIndex(index)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockDestination extends StatelessWidget {
  final AppNavDestination destination;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DockDestination({
    required this.destination,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final backgroundColor = isSelected
        ? themeColors.workspaceSelection
        : Colors.transparent;
    final foregroundColor = isSelected
        ? themeColors.accentPrimary
        : themeColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.p6),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSizes.p4,
              children: [
                Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  color: foregroundColor,
                ),
                Text(
                  label,
                  style: AppTypography.micro.copyWith(color: foregroundColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
