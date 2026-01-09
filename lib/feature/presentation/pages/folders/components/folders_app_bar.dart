import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/screens/settings_screen.dart';

/// AppBar for folders screen with integrated search functionality.
///
/// Manages its own search state internally, including the search visibility
/// toggle and text controller. The search bar appears as a bottom widget
/// of the SliverAppBar when visible.
class FoldersAppBar extends StatefulWidget {
  const FoldersAppBar({super.key});

  @override
  State<FoldersAppBar> createState() => _FoldersAppBarState();
}

class _FoldersAppBarState extends State<FoldersAppBar> {
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

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        context.read<FoldersCubit>().clearSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<FoldersCubit>().clearSearch();
    setState(() {});
  }

  void _onSettingsTap() {
    SettingsScreen.go(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return SliverAppBar(
      floating: true,
      backgroundColor: themeColors.bgPrimary,
      surfaceTintColor: Colors.transparent,
      title: Text('Заметки', style: textTheme.displayLarge),
      actionsPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
      actions: [
        IconButton(
          icon: Icon(
            _isSearchVisible ? Icons.close : Icons.search,
            color: themeColors.textSecondary,
          ),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: themeColors.textSecondary),
          onPressed: _onSettingsTap,
        ),
      ],
      bottom: _isSearchVisible
          ? PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: _SearchField(
                controller: _searchController,
                onClear: _clearSearch,
                onChanged: (query) =>
                    context.read<FoldersCubit>().search(query),
              ),
            )
          : null,
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onClear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.p8,
        horizontal: AppSizes.screenPadding,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
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
    );
  }
}
