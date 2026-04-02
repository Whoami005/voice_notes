import 'package:flutter/material.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class UnsavedChangesDialog {
  const UnsavedChangesDialog._();

  static Future<bool?> show(BuildContext context) async {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    return showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.unsavedChangesLeave,
              style: TextStyle(color: themeColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.unsavedChangesStay),
          ),
        ],
      ),
    );
  }
}
