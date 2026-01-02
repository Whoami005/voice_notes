import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/presentation/widgets/menus/dropdown_menu.dart';

class FolderDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final FolderEntity folder;
  final bool isSearchVisible;
  final VoidCallback onToggleSearch;
  final VoidCallback onEditFolder;
  final VoidCallback onDeleteFolder;

  const FolderDetailAppBar({
    required this.folder,
    required this.isSearchVisible,
    required this.onToggleSearch,
    required this.onEditFolder,
    required this.onDeleteFolder,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return AppBar(
      title: Row(
        spacing: AppSizes.p10,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: folder.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.p8),
            ),
            child: Icon(folder.iconData, color: folder.color, size: 18),
          ),
          Flexible(
            child: Text(
              folder.name,
              style: textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8),
      actions: [
        IconButton(
          icon: Icon(
            isSearchVisible ? Icons.close : Icons.search,
            color: themeColors.textSecondary,
          ),
          onPressed: onToggleSearch,
        ),
        AppDropdownMenu(
          items: [
            AppMenuItem(
              icon: Icons.edit_outlined,
              label: 'Редактировать',
              onTap: onEditFolder,
            ),
            AppMenuItem(
              icon: Icons.delete_outline,
              label: 'Удалить папку',
              color: themeColors.error,
              onTap: onDeleteFolder,
            ),
          ],
        ),
      ],
    );
  }
}
