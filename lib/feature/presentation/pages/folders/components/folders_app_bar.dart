import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/feature/presentation/pages/folder_search/screens/folder_search_screen.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/screens/general_settings_screen.dart';

/// AppBar for the folders screen.
///
/// Tapping the search icon pushes the dedicated [FolderSearchScreen] route
/// instead of revealing an inline search field. The icon is hidden when
/// the folders list is empty (nothing to search).
class FoldersAppBar extends StatelessWidget {
  const FoldersAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final isEmpty = context.select(
      (FoldersCubit cubit) => cubit.state.requireData.folders.isEmpty,
    );

    return SliverAppBar(
      floating: true,
      backgroundColor: themeColors.bgPrimary,
      surfaceTintColor: AppColors.transparent,
      title: Text(context.l10n.foldersTitle, style: textTheme.displayLarge),
      actionsPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
      actions: [
        if (!isEmpty)
          IconButton(
            icon: Icon(Icons.search, color: themeColors.textSecondary),
            onPressed: () => FolderSearchScreen.go(context),
          ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: themeColors.textSecondary),
          onPressed: () => GeneralSettingsScreen.go(context),
        ),
      ],
    );
  }
}
