import 'package:voice_notes/core/error/app_failure.dart';

/// Базовый sealed class для стандартных UI-эффектов приложения.
sealed class AppEffect {
  const AppEffect();
}

/// Показать диалог ошибки
final class ShowErrorEffect extends AppEffect {
  final AppFailure failure;

  const ShowErrorEffect(this.failure);

  @override
  String toString() => 'ShowErrorEffect(${failure.message})';
}

/// Показать snackbar успеха
final class ShowSuccessEffect extends AppEffect {
  final String message;

  const ShowSuccessEffect(this.message);

  @override
  String toString() => 'ShowSuccessEffect($message)';
}
