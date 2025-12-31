import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

/// Диалог для отображения ошибок
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final String buttonText;
  final IconData icon;
  final Color? iconColor;

  const ErrorDialog({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
    this.details,
    this.buttonText = 'Понятно',
    this.iconColor,
  });

  /// Показать диалог об ошибке сети
  static Future<void> showNetworkError(BuildContext context) {
    return _show(
      context: context,
      title: 'Нет подключения к интернету',
      message:
          'Для скачивания модели необходимо подключение к интернету. '
          'Проверьте настройки сети и попробуйте снова.',
      icon: Icons.wifi_off_rounded,
    );
  }

  static String _storageDetails({int? requiredBytes, int? availableBytes}) {
    String details = '';
    if (requiredBytes != null) {
      details += 'Требуется: ${_formatBytes(requiredBytes)}';
    }
    if (availableBytes != null) {
      if (details.isNotEmpty) details += '\n';
      details += 'Доступно: ${_formatBytes(availableBytes)}';
    }

    return details;
  }

  /// Показать диалог о недостаточном месте
  static Future<void> showStorageError(
    BuildContext context, {
    int? requiredBytes,
    int? availableBytes,
  }) {
    final String details = _storageDetails(
      requiredBytes: requiredBytes,
      availableBytes: availableBytes,
    );

    return _show(
      context: context,
      title: 'Недостаточно места',
      message:
          'Для скачивания и распаковки модели требуется больше '
          'свободного места на устройстве.',
      details: details.isNotEmpty ? details : null,
      icon: Icons.storage_rounded,
    );
  }

  /// Показать диалог на основе AppFailure
  static Future<void> showFromFailure(
    BuildContext context,
    AppFailure failure,
  ) {
    return switch (failure) {
      NetworkFailure() => showNetworkError(context),
      StorageFailure(:final requiredBytes, :final availableBytes) =>
        showStorageError(
          context,
          requiredBytes: requiredBytes,
          availableBytes: availableBytes,
        ),
      _ => _show(
        context: context,
        title: 'Ошибка',
        message: failure.message,
        icon: Icons.error_outline_rounded,
      ),
    };
  }

  static Future<void> _show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    String? details,
    Color? iconColor,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ErrorDialog(
          title: title,
          message: message,
          details: details,
          icon: icon,
          iconColor: iconColor,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final effectiveIconColor = iconColor ?? themeColors.warning;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSizes.screenPadding),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: themeColors.bgElevated,
          borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: AppSizes.iconLarge,
                ),
              ),
              AppSpacer.p16,
              Text(
                title,
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacer.p8,
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: themeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (details != null) ...[
                AppSpacer.p12,
                Container(
                  padding: const EdgeInsets.all(AppSizes.p12),
                  decoration: BoxDecoration(
                    color: themeColors.bgTertiary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: Text(
                    details!,
                    style: textTheme.bodySmall?.copyWith(
                      color: themeColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              AppSpacer.p24,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
