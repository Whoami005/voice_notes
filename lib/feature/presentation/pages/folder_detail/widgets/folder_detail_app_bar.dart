import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/routes/folders_route_presentation.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/base_preferred_app_bar.dart';
import 'package:voice_notes/feature/presentation/widgets/folder_icon_badge.dart';
import 'package:voice_notes/feature/presentation/widgets/menus/dropdown_menu.dart';

class FolderDetailAppBar extends BasePreferredAppBar {
  final VoidCallback onDeleteFolder;
  final bool showBackButton;

  const FolderDetailAppBar({
    required this.onDeleteFolder,
    super.key,
    this.showBackButton = true,
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
    final presentation = FoldersRoutePresentation.fromContext(context);
    final useWorkspacePane = presentation.isWorkspaceActive;
    final state = context.watch<FolderDetailCubit>().state;
    final folder = state.requireData.folder;

    return AppBar(
      automaticallyImplyLeading: widget.showBackButton,
      backgroundColor: useWorkspacePane
          ? themeColors.workspacePane
          : themeColors.bgPrimary,
      surfaceTintColor: Colors.transparent,
      bottom: widget.bottom,
      toolbarHeight: widget.toolbarHeight,
      title: Row(
        spacing: AppSizes.p10,
        mainAxisSize: MainAxisSize.min,
        children: [
          FolderIconBadge(
            icon: folder.icon,
            color: folder.color,
            size: AppSizes.p32,
            iconSize: 18,
            borderRadius: AppSizes.p8,
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
        AppDropdownMenu(
          items: [
            AppMenuItem(
              icon: Icons.delete_outline,
              label: context.l10n.deleteFolderAppBarAction,
              color: themeColors.error,
              onTap: widget.onDeleteFolder,
            ),
          ],
        ),
      ],
    );
  }
}
