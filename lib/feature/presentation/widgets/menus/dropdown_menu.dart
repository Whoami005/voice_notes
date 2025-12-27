import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class AppMenuItem {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const AppMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class AppDropdownMenu extends StatelessWidget {
  final List<AppMenuItem> items;
  final Widget? child;
  final IconData? icon;
  final Offset offset;

  const AppDropdownMenu({
    required this.items,
    super.key,
    this.child,
    this.icon,
    this.offset = const Offset(0, 8),
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return PopupMenuButton<int>(
      offset: offset,
      constraints: const BoxConstraints(minWidth: 200),
      position: PopupMenuPosition.under,
      onSelected: (index) => items[index].onTap(),
      itemBuilder: (context) {
        return List.generate(items.length, (index) {
          final item = items[index];
          final isDestructive = item.color != null;
          final itemColor = item.color ?? themeColors.textPrimary;

          return PopupMenuItem<int>(
            value: index,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p14,
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: itemColor),
                AppSpacer.p12,
                Expanded(
                  child: Text(
                    item.label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: itemColor,
                      fontWeight: isDestructive ? FontWeight.w500 : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
      child:
          child ??
          Padding(
            padding: const EdgeInsets.all(AppSizes.p8),
            child: Icon(
              icon ?? Icons.more_vert,
              color: themeColors.textSecondary,
              size: AppSizes.iconLarge,
            ),
          ),
    );
  }
}
