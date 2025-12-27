import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/routes.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/folder.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/folder_card.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/quick_record_card.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/create_folder_sheet.dart';
import 'package:voice_notes/feature/presentation/widgets/buttons/app_fab.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();

  // Mock data for UI preview
  final List<Folder> _folders = [
    Folder(
      id: '1',
      name: 'Работа',
      description: 'Рабочие заметки и митинги',
      color: AppColors.folderColors[2],
      icon: Icons.work,
      notesCount: 15,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Folder(
      id: '2',
      name: 'Личное',
      color: AppColors.folderColors[3],
      icon: Icons.favorite,
      notesCount: 8,
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Folder(
      id: '3',
      name: 'Книги',
      description: 'Цитаты и идеи из книг',
      color: AppColors.folderColors[4],
      icon: Icons.book,
      notesCount: 23,
      lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Folder(
      id: '4',
      name: 'Музыка',
      color: AppColors.folderColors[0],
      icon: Icons.music_note,
      notesCount: 5,
      lastUpdated: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      floatingActionButton: AppFab(
        icon: Icons.add,
        onPressed: _onCreateFolder,
      ),
      body: SafeArea(
        bottom: false,
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
                  _SectionHeader(count: _folders.length),
                  AppSpacer.p12,
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
              ),
              sliver: SliverList.builder(
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.p12),
                    child: FolderCard(
                      folder: _folders[index],
                      onTap: () => _onFolderTap(_folders[index]),
                      onLongPress: () => _onFolderLongPress(_folders[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
  }

  void _onSettingsTap() {
    context.go(AppRoutes.settings);
  }

  void _onQuickRecord() {
    // TODO: Start quick recording
  }

  void _onFolderTap(Folder folder) {
    context.go('/folders/${folder.id}');
  }

  void _onFolderLongPress(Folder folder) {
    // TODO: Show folder context menu
  }

  Future<void> _onCreateFolder() async {
    final result = await CreateFolderSheet.show(context: context);
    if (result != null) {
      // TODO: Add folder via state management
    }
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
      title: Text(
        'Заметки',
        style: textTheme.displayLarge,
      ),
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

  const _SearchBar({
    required this.controller,
    required this.onClear,
  });

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
