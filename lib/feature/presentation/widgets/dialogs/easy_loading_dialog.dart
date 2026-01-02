import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easy_dialogs/flutter_easy_dialogs.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';

/// Диалог загрузки на основе flutter_easy_dialogs
///
/// Предоставляет расширенные возможности:
/// - Анимации (fade, slide, scale)
/// - Позиционирование (center, top, bottom, custom)
/// - Draggable диалоги
/// - Возможность отмены через CancelToken
///
/// Требует инициализации FlutterEasyDialogs.builder() в MaterialApp
class EasyLoadingDialog {
  const EasyLoadingDialog._();

  static CancelToken? _cancelToken;
  static EasyDialog? _dialog;

  /// Показывает диалог с возможностью отмены
  ///
  /// [future] - функция, принимающая CancelToken и возвращающая Future
  /// [onCancel] - callback при отмене
  /// [cancelButtonText] - текст кнопки отмены
  /// [position] - позиция диалога на экране
  /// [animation] - тип анимации
  /// [draggable] - возможность перетаскивания диалога
  static Future<T?> showCancelable<T>({
    required Future<T> Function(CancelToken cancelToken) future,
    VoidCallback? onCancel,
    String cancelButtonText = 'Отменить',
    EasyDialogPosition position = EasyDialogPosition.center,
    EasyDialogAnimation animation = const EasyDialogAnimation.fade(),
    bool draggable = false,
  }) async {
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;

    try {
      return await _executeWithDialog<T>(
        future: () => future(cancelToken),
        content: EasyDialogContentWidget(
          onCancel: () => _handleCancel(onCancel),
          cancelButtonText: cancelButtonText,
        ),
        position: position,
        animation: animation,
        draggable: draggable,
      );
    } finally {
      _cancelToken = null;
    }
  }

  /// Показывает простой диалог загрузки без отмены
  ///
  /// [future] - функция, возвращающая Future
  /// [position] - позиция диалога
  /// [animation] - тип анимации
  /// [showIndicator] - показывать ли индикатор загрузки
  static Future<T?> showFuture<T>({
    required Future<T> Function() future,
    EasyDialogPosition position = EasyDialogPosition.center,
    EasyDialogAnimation animation = const EasyDialogAnimation.fade(),
    bool showIndicator = true,
  }) {
    return _executeWithDialog<T>(
      future: future,
      content: Center(
        child: showIndicator
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
      position: position,
      animation: animation,
    );
  }

  /// Скрывает диалог используя extension метод
  static void hide() {
    _dialog?.hide();
    _dialog = null;
  }

  /// Выполняет future с показом диалога и управлением его жизненным циклом
  static Future<T?> _executeWithDialog<T>({
    required Future<T> Function() future,
    required Widget content,
    required EasyDialogPosition position,
    required EasyDialogAnimation animation,
    bool draggable = false,
  }) async {
    // Создаем диалог
    _dialog = EasyDialog.positioned(
      position: position,
      decoration: animation,
      autoHideDuration: null,
      content: content,
    );

    // Показываем диалог без await — он должен отображаться пока future выполняется
    unawaited(
      draggable ? _dialog!.draggable().show<void>() : _dialog!.show<void>(),
    );

    try {
      return await future();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return null;
      }
      rethrow;
    } finally {
      hide();
    }
  }

  /// Обрабатывает отмену операции
  static void _handleCancel(VoidCallback? onCancel) {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('Операция отменена пользователем');
    }

    onCancel?.call();
    hide();
  }
}

/// Виджет контента диалога с индикатором и кнопкой отмены
class EasyDialogContentWidget extends StatelessWidget {
  final VoidCallback onCancel;
  final String cancelButtonText;
  final bool showIndicator;

  const EasyDialogContentWidget({
    required this.onCancel,
    required this.cancelButtonText,
    this.showIndicator = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        spacing: AppSizes.p24,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIndicator) const CircularProgressIndicator(),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p32,
                vertical: AppSizes.p12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              cancelButtonText,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
