import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/base_preferred_app_bar.dart';
import 'package:voice_notes/feature/presentation/widgets/menus/dropdown_menu.dart';

class FolderDetailAppBar extends BasePreferredAppBar {
  final bool isSearchVisible;
  final VoidCallback onToggleSearch;
  final VoidCallback onEditFolder;
  final VoidCallback onDeleteFolder;

  const FolderDetailAppBar({
    required this.isSearchVisible,
    required this.onToggleSearch,
    required this.onEditFolder,
    required this.onDeleteFolder,
    super.key,
    super.toolbarHeight,
    super.bottom,
  });

  @override
  State<FolderDetailAppBar> createState() => _FolderDetailAppBarState();
}

class _FolderDetailAppBarState extends State<FolderDetailAppBar> {
  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final state = context.watch<FolderDetailCubit>().state;
    final folder = state.requireData.folder;

    return AppBar(
      bottom: widget.bottom,
      toolbarHeight: widget.toolbarHeight,
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
        // IconButton(
        //   icon: Icon(
        //     widget.isSearchVisible ? Icons.close : Icons.search,
        //     color: themeColors.textSecondary,
        //   ),
        //   onPressed: widget.onToggleSearch,
        // ),
        AppDropdownMenu(
          items: [
            // AppMenuItem(
            //   icon: Icons.edit_outlined,
            //   label: 'Редактировать',
            //   onTap: widget.onEditFolder,
            // ),
            AppMenuItem(
              icon: Icons.delete_outline,
              label: 'Удалить папку',
              color: themeColors.error,
              onTap: widget.onDeleteFolder,
            ),
          ],
        ),
      ],
    );
  }
}
