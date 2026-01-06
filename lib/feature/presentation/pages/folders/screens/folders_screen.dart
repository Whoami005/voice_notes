import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/state.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/screens/folder_detail_screen.dart';
import 'package:voice_notes/feature/presentation/pages/folders/components/folders_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/folders/components/folders_list_section.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/folder_actions_sheet.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/quick_record_card.dart';
import 'package:voice_notes/feature/presentation/pages/settings/screens/settings_screen.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/create_folder_sheet.dart';
import 'package:voice_notes/feature/presentation/widgets/buttons/app_fab.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

class FoldersScreen extends StatefulWidget implements AppRouteWrapper {
  const FoldersScreen({super.key});

  /// Навигация на главный экран папок
  static void go(BuildContext context) {
    context.go(AppRoutes.folders.root);
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => FoldersCubit(repository: getIt<FolderRepository>()),
      child: this,
    );
  }

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  @override
  Widget build(BuildContext context) {
    return BaseStateScaffold<FoldersCubit, FoldersState>(
      title: 'Заметки',
      onSuccess: (context, state) {
        return Scaffold(
          floatingActionButton: AppFab(
            icon: Icons.add,
            onPressed: _onCreateFolder,
          ),
          body: SafeArea(
            bottom: false,
            child: RefreshableWrapper<FoldersCubit>(
              child: CustomScrollView(
                slivers: [
                  FoldersAppBar(onSettingsTap: _onSettingsTap),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSizes.screenPadding),
                    sliver: SliverToBoxAdapter(
                      child: QuickRecordCard(onTap: _onQuickRecord),
                    ),
                  ),
                  FoldersListSection(
                    onFolderTap: _onFolderTap,
                    onFolderLongPress: _onFolderLongPress,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onSettingsTap() {
    SettingsScreen.go(context);
  }

  void _onQuickRecord() {
    // TODO: Start quick recording
  }

  void _onFolderTap(FolderEntity folder) {
    FolderDetailScreen.go(context, folderId: folder.uid);
  }

  Future<void> _onFolderLongPress(FolderEntity folder) async {
    final action = await FolderActionsSheet.show(context, folder);

    if (!mounted || action == null) return;

    switch (action) {
      case FolderAction.edit:
        await _onEditFolder(folder);
      case FolderAction.delete:
        await _onDeleteFolder(folder);
    }
  }

  Future<void> _onEditFolder(FolderEntity folder) async {
    final result = await CreateFolderSheet.show(
      context: context,
      initialName: folder.name,
      initialDescription: folder.description,
      initialColor: folder.color,
      initialIcon: folder.icon,
    );

    if (result != null && mounted) {
      final updatedFolder = folder.copyWith(
        name: result.name,
        description: result.description,
        color: result.color,
        icon: result.icon,
      );
      await context.read<FoldersCubit>().updateFolder(updatedFolder);
    }
  }

  Future<void> _onDeleteFolder(FolderEntity folder) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Удалить папку?',
      message:
          'Папка "${folder.name}" и все заметки в ней '
          'будут удалены безвозвратно.',
      confirmText: 'Удалить',
      icon: Icons.delete_outline,
    );

    if ((confirmed ?? false) && mounted) {
      await context.read<FoldersCubit>().deleteFolder(folder.uid);
    }
  }

  Future<void> _onCreateFolder() async {
    final result = await CreateFolderSheet.show(context: context);

    if (result != null && mounted) {
      await context.read<FoldersCubit>().createFolder(result);
    }
  }
}
