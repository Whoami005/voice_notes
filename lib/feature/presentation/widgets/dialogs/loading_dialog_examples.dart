import 'package:flutter/material.dart';
import 'package:flutter_easy_dialogs/flutter_easy_dialogs.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/easy_loading_dialog.dart';

/// Примеры использования всех трех вариантов загрузочных диалогов:
/// 1. LoadingDialog - существующий, для быстрых операций
/// 2. CancelableLoadingDialog - с возможностью отмены
/// 3. EasyLoadingDialog - с расширенными возможностями

class LoadingDialogExamples {
  // ============================================
  // 3. EasyLoadingDialog - Расширенные возможности
  // ============================================

  /// Базовое использование EasyLoadingDialog
  static Future<void> exampleEasyDialog(BuildContext context) async {
    await EasyLoadingDialog.showCancelable<String>(
      future: (cancelToken) async {
        await Future.delayed(const Duration(seconds: 2));
        return 'Готово';
      },
      onCancel: () {
        debugPrint('Отменено через EasyLoadingDialog');
      },
    );
  }

  /// EasyLoadingDialog с fade анимацией
  static Future<void> exampleEasyDialogFade(BuildContext context) async {
    await EasyLoadingDialog.showCancelable(
      future: (cancelToken) async {
        await Future.delayed(const Duration(seconds: 2));
        return 'Готово';
      },
      onCancel: () => debugPrint('Отменено'),
    );
  }

  /// EasyLoadingDialog с slide анимацией сверху
  static Future<void> exampleEasyDialogSlideTop(BuildContext context) async {
    await EasyLoadingDialog.showCancelable(
      position: EasyDialogPosition.top,
      animation: const EasyDialogAnimation.slideVertical(),
      future: (cancelToken) async {
        await Future.delayed(const Duration(seconds: 2));
        return 'Готово';
      },
      onCancel: () => debugPrint('Отменено'),
    );
  }

  /// EasyLoadingDialog с slide анимацией снизу
  static Future<void> exampleEasyDialogSlideBottom(BuildContext context) async {
    await EasyLoadingDialog.showCancelable(
      position: EasyDialogPosition.bottom,
      animation: const EasyDialogAnimation.slideHorizontal(),
      future: (cancelToken) async {
        await Future.delayed(const Duration(seconds: 2));
        return 'Готово';
      },
      onCancel: () => debugPrint('Отменено'),
    );
  }

  /// EasyLoadingDialog с draggable функцией
  static Future<void> exampleEasyDialogDraggable(BuildContext context) async {
    await EasyLoadingDialog.showCancelable(
      draggable: true, // Диалог можно перетаскивать
      future: (cancelToken) async {
        await Future.delayed(const Duration(seconds: 3));
        return 'Готово';
      },
      onCancel: () => debugPrint('Отменено'),
    );
  }

  /// EasyLoadingDialog простой (без отмены)
  static Future<void> exampleEasyDialogSimple(BuildContext context) async {
    await EasyLoadingDialog.showFuture(
      future: () async {
        await Future.delayed(const Duration(seconds: 2));
        return 'Данные загружены';
      },
    );
  }

  /// EasyLoadingDialog с scale анимацией
  static Future<void> exampleEasyDialogScale(BuildContext context) async {
    await EasyLoadingDialog.showFuture(
      animation: const EasyDialogAnimation.bounce(),
      future: () async {
        await Future.delayed(const Duration(seconds: 2));
        return 'Готово';
      },
    );
  }
}
