import 'package:flutter/widgets.dart';

/// Маркер-интерфейс для всех эффектов приложения.
///
/// Используется как базовый тип для всех эффектов в системе.
/// Позволяет унифицировать работу с эффектами без необходимости
/// указывать конкретный тип в дженериках.
abstract interface class BaseEffect {}

/// Эффекты с автоматической обработкой.
///
/// Если эффект реализует этот интерфейс, он будет автоматически
/// обработан в виджетах (AsyncStateBody, StatusStateBody и др.)
/// когда не передан кастомный onEffect callback.
abstract interface class HandledEffect implements BaseEffect {
  /// Обработать эффект в контексте (показать dialog, snackbar и т.д.)
  void handle(BuildContext context);
}
