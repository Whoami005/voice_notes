import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/folder_action_l10n.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';

/// Available actions for folder context menu.
enum FolderAction { edit, delete }

/// Bottom sheet with folder actions.
///
/// Example:
/// ```dart
/// final action = await FolderActionsSheet.show(context, folder);
/// if (action == FolderAction.edit) { ... }
/// ```
class FolderActionsSheet extends StatelessWidget {
  final FolderEntity folder;

  const FolderActionsSheet._({required this.folder});

  /// Shows the action sheet and returns the selected action.
  static Future<FolderAction?> show(BuildContext context, FolderEntity folder) {
    return showModalBottomSheet<FolderAction>(
      context: context,
      builder: (context) => FolderActionsSheet._(folder: folder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              title: Text(FolderAction.edit.title(l10n)),
              onTap: () => Navigator.pop(context, FolderAction.edit),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: themeColors.error),
              title: Text(
                FolderAction.delete.title(l10n),
                style: TextStyle(color: themeColors.error),
              ),
              onTap: () => Navigator.pop(context, FolderAction.delete),
            ),
          ],
        ),
      ),
    );
  }
}
