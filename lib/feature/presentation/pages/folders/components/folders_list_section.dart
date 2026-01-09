import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/screens/folder_detail_screen.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/folder_actions_sheet.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/folder_card.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/folders_section_header.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/new_folder_button.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/create_folder_sheet.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/lists/bloc_sliver_list_section.dart';

/// Sliver section displaying the list of folders with a header.
///
/// Contains all folder action logic: navigation, create, edit, delete.
class FoldersListSection extends StatelessWidget {
  const FoldersListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSliverListSection<
      FoldersCubit,
      AsyncState<FoldersState>,
      FolderEntity
    >(
      selector: (state) => state.requireData.filteredFolders,
      padding: const EdgeInsets.only(
        top: AppSizes.p12,
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        bottom: AppSizes.screenPadding,
      ),
      headerBuilder: (context, items) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.p12),
        child: FoldersSectionHeader(
          title: 'Папки',
          count: items.length,
          trailing: NewFolderButton(onPressed: () => _onCreateFolder(context)),
        ),
      ),
      separatorBuilder: (_, _) => AppSpacer.p12,
      itemBuilder: (context, folder, index) => FolderCard(
        folder: folder,
        onTap: () => _onFolderTap(context, folder),
        onLongPress: () => _onFolderLongPress(context, folder),
      ),
    );
  }

  void _onFolderTap(BuildContext context, FolderEntity folder) {
    FolderDetailScreen.go(context, folderId: folder.uid);
  }

  Future<void> _onFolderLongPress(
    BuildContext context,
    FolderEntity folder,
  ) async {
    final action = await FolderActionsSheet.show(context, folder);

    if (!context.mounted || action == null) return;

    switch (action) {
      case FolderAction.edit:
        await _onEditFolder(context, folder);
      case FolderAction.delete:
        await _onDeleteFolder(context, folder);
    }
  }

  Future<void> _onEditFolder(BuildContext context, FolderEntity folder) async {
    final result = await CreateFolderSheet.show(
      context: context,
      initialName: folder.name,
      initialDescription: folder.description,
      initialColor: folder.color,
      initialIcon: folder.icon,
    );

    if (result != null && context.mounted) {
      final updatedFolder = folder.copyWith(
        name: result.name,
        description: result.description,
        color: result.color,
        icon: result.icon,
      );
      await context.read<FoldersCubit>().updateFolder(updatedFolder);
    }
  }

  Future<void> _onDeleteFolder(
    BuildContext context,
    FolderEntity folder,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Удалить папку?',
      message:
          'Папка "${folder.name}" и все заметки в ней '
          'будут удалены безвозвратно.',
      confirmText: 'Удалить',
      icon: Icons.delete_outline,
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<FoldersCubit>().deleteFolder(folder.uid);
    }
  }

  Future<void> _onCreateFolder(BuildContext context) async {
    final result = await CreateFolderSheet.show(context: context);

    if (result != null && context.mounted) {
      await context.read<FoldersCubit>().createFolder(result);
    }
  }
}
