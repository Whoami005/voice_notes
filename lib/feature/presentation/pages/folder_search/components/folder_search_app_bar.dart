import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_colors.dart';

/// Pinned SliverAppBar for the folder search screen.
class FolderSearchAppBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  const FolderSearchAppBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final hasText = controller.text.isNotEmpty;

    return SliverAppBar(
      pinned: true,
      backgroundColor: themeColors.bgPrimary,
      surfaceTintColor: AppColors.transparent,
      titleSpacing: 0,
      leading: BackButton(color: themeColors.textPrimary),
      title: Padding(
        padding: const EdgeInsets.only(right: AppSizes.p16),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.l10n.foldersSearchHint,
            prefixIcon: Icon(Icons.search, color: themeColors.textTertiary),
            suffixIcon: hasText
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
