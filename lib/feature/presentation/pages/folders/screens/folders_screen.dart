import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/state.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/folder_card.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/quick_record_card.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/create_folder_sheet.dart';
import 'package:voice_notes/feature/presentation/widgets/buttons/app_fab.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

class FoldersScreen extends StatefulWidget implements AppRouteWrapper {
  const FoldersScreen({super.key});

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
  bool _isSearchVisible = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseStateScaffold<FoldersCubit, FoldersState>(
      title: 'Заметки',
      buildWhen: (c, p) => true,
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
                  _AppBar(
                    isSearchVisible: _isSearchVisible,
                    onSearchToggle: _toggleSearch,
                    onSettingsTap: _onSettingsTap,
                  ),
                  if (_isSearchVisible)
                    _SearchBar(
                      controller: _searchController,
                      onClear: _clearSearch,
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSizes.screenPadding),
                    sliver: SliverList.list(
                      children: [
                        QuickRecordCard(onTap: _onQuickRecord),
                        AppSpacer.p24,
                        _SectionHeader(count: state.folders.length),
                        AppSpacer.p12,
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenPadding,
                    ),
                    sliver: SliverList.builder(
                      itemCount: state.folders.length,
                      itemBuilder: (context, index) {
                        final folder = state.folders[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.p12),
                          child: FolderCard(
                            folder: folder,
                            onTap: () => _onFolderTap(folder),
                            onLongPress: () => _onFolderLongPress(folder),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) _searchController.clear();
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
    });
  }

  void _onSettingsTap() {
    context.go(AppRoutes.settings);
  }

  void _onQuickRecord() {
    // TODO: Start quick recording
  }

  Future<void> _onFolderTap(FolderEntity folder) async {
    context.go('/folders/${folder.uid}');
  }

  Future<void> _onFolderLongPress(FolderEntity folder) async {
    final action = await showModalBottomSheet<_FolderAction>(
      context: context,
      builder: (context) => _FolderActionsSheet(folder: folder),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _FolderAction.edit:
        await _onEditFolder(folder);
      case _FolderAction.delete:
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

enum _FolderAction { edit, delete }

class _FolderActionsSheet extends StatelessWidget {
  final FolderEntity folder;

  const _FolderActionsSheet({required this.folder});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizes.p16),
              decoration: BoxDecoration(
                color: themeColors.bgTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: themeColors.textPrimary,
              ),
              title: const Text('Редактировать'),
              onTap: () => Navigator.pop(context, _FolderAction.edit),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: themeColors.error),
              title: Text(
                'Удалить',
                style: TextStyle(color: themeColors.error),
              ),
              onTap: () => Navigator.pop(context, _FolderAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final bool isSearchVisible;
  final VoidCallback onSearchToggle;
  final VoidCallback onSettingsTap;

  const _AppBar({
    required this.isSearchVisible,
    required this.onSearchToggle,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return SliverAppBar(
      floating: true,
      backgroundColor: themeColors.bgPrimary,
      surfaceTintColor: Colors.transparent,
      title: Text('Заметки', style: textTheme.displayLarge),
      actions: [
        IconButton(
          icon: Icon(
            isSearchVisible ? Icons.close : Icons.search,
            color: themeColors.textSecondary,
          ),
          onPressed: onSearchToggle,
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: themeColors.textSecondary),
          onPressed: onSettingsTap,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenPadding,
          vertical: AppSizes.p8,
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Поиск заметок...',
            prefixIcon: Icon(Icons.search, color: themeColors.textTertiary),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: themeColors.textTertiary),
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final int count;

  const _SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Row(
      children: [
        Text(
          'Папки',
          style: AppTypography.overline.copyWith(
            color: themeColors.textSecondary,
          ),
        ),
        AppSpacer.p8,
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p8,
            vertical: AppSizes.p2,
          ),
          decoration: BoxDecoration(
            color: themeColors.bgTertiary,
            borderRadius: BorderRadius.circular(AppSizes.chipRadius),
          ),
          child: Text(
            '$count',
            style: AppTypography.captionSmall.copyWith(
              color: themeColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
