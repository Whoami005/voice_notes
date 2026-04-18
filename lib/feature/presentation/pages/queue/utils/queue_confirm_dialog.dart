import 'package:flutter/material.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

Future<bool> showQueueDestructiveConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final themeColors = context.themeColors;
  final l10n = context.l10n;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.queueConfirmKeep),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: themeColors.error),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return result ?? false;
}
