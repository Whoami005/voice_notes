import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/folder_action_l10n.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';

/// Available actions for folder context menu.
enum FolderAction { edit, delete }

/// Bottom sheet with folder actions.
class FolderActionsSheet extends StatelessWidget {
  final FolderEntity folder;

  const FolderActionsSheet._({required this.folder});

  static Future<FolderAction?> show(BuildContext context, FolderEntity folder) {
    return showModalBottomSheet<FolderAction>(
      useRootNavigator: true,
      context: context,
      builder: (context) => FolderActionsSheet._(folder: folder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    return SafeArea(
      child: ListView(
        physics: const ClampingScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
        children: [
          ListTile(
            leading: Icon(Icons.edit_outlined, color: themeColors.textPrimary),
            title: Text(FolderAction.edit.title(l10n)),
            onTap: () => context.router.pop(FolderAction.edit),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: themeColors.error),
            title: Text(
              FolderAction.delete.title(l10n),
              style: TextStyle(color: themeColors.error),
            ),
            onTap: () => context.router.pop(FolderAction.delete),
          ),
        ],
      ),
    );
  }
}
