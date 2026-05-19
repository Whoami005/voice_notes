import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/main_branch_navigation.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/feature/presentation/pages/folder_search/screens/folder_search_screen.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';

/// AppBar for the folders screen.
///
/// Tapping the search icon pushes the dedicated [FolderSearchScreen] route
/// instead of revealing an inline search field. The icon is hidden when
/// the folders list is empty (nothing to search).
class FoldersAppBar extends StatelessWidget {
  final bool useWorkspaceStyle;

  const FoldersAppBar({super.key, this.useWorkspaceStyle = false});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final isEmpty = context.select(
      (FoldersCubit cubit) => cubit.state.requireData.folders.isEmpty,
    );

    return SliverAppBar(
      floating: true,
      backgroundColor: useWorkspaceStyle
          ? themeColors.workspacePane
          : themeColors.workspaceShell,
      surfaceTintColor: AppColors.transparent,
      title: Text(
        context.l10n.foldersTitle,
        style: useWorkspaceStyle
            ? textTheme.titleLarge
            : textTheme.displayLarge,
      ),
      actionsPadding: EdgeInsets.symmetric(
        horizontal: useWorkspaceStyle ? AppSizes.p4 : AppSizes.p8,
      ),
      actions: [
        if (!isEmpty)
          IconButton(
            icon: Icon(Icons.search, color: themeColors.textSecondary),
            onPressed: () => FolderSearchScreen.go(context),
          ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: themeColors.textSecondary),
          onPressed: () => _openSettings(context),
        ),
      ],
    );
  }

  void _openSettings(BuildContext context) {
    context.goMainBranch(AppMainBranch.settings);
  }
}
