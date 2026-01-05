import 'package:flutter/material.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class UnsavedChangesDialog {
  const UnsavedChangesDialog._();

  static Future<bool?> show(BuildContext context) async {
    final themeColors = context.themeColors;

    return showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Несохранённые изменения'),
        content: const Text(
          'У вас есть несохранённые изменения. '
          'Вы уверены, что хотите выйти ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Выйти', style: TextStyle(color: themeColors.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
        ],
      ),
    );
  }
}
