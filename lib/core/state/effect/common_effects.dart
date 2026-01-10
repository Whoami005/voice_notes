import 'package:flutter/material.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/state/effect/base_effect.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';

/// Базовый sealed class для стандартных UI-эффектов приложения.
///
/// Реализует [HandledEffect] для автоматической обработки в виджетах.
sealed class AppEffect implements HandledEffect {
  const AppEffect();
}

/// Показать диалог ошибки
final class ShowErrorEffect extends AppEffect {
  final AppFailure failure;

  const ShowErrorEffect(this.failure);

  @override
  void handle(BuildContext context) =>
      ErrorDialog.showFromFailure(context, failure);

  @override
  String toString() => 'ShowErrorEffect(${failure.message})';
}

/// Показать snackbar успеха
final class ShowSuccessEffect extends AppEffect {
  final String message;

  const ShowSuccessEffect(this.message);

  @override
  void handle(BuildContext context) {
    final showSnackBar = ScaffoldMessenger.of(context).showSnackBar;

    showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  String toString() => 'ShowSuccessEffect($message)';
}
