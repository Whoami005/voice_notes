import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

/// Sliver containing the folder search text field.
///
/// Lives directly under `FolderSearchAppBar` in the search screen body.
/// Owns no state — receives controller, focus node and clear callback
/// from the parent screen, which drives the search cubit on every change.
class FolderSearchInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  const FolderSearchInput({
    required this.controller,
    required this.focusNode,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final hasText = controller.text.isNotEmpty;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.p12,
          AppSizes.screenPadding,
          AppSizes.p8,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.l10n.searchHint,
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
