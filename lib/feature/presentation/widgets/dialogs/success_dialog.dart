import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

/// Диалог успешного завершения операции
class SuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? previewText;
  final IconData icon;
  final Duration autoCloseDuration;

  const SuccessDialog({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
    this.previewText,
    this.autoCloseDuration = const Duration(milliseconds: 2500),
  });

  /// Показать диалог успешного копирования в буфер
  static Future<void> showClipboardSuccess(
    BuildContext context, {
    String? text,
  }) {
    return _show(
      context: context,
      title: 'Скопировано!',
      message: 'Текст добавлен в буфер обмена',
      previewText: text,
      icon: Icons.check_circle_outline,
    );
  }

  static Future<void> _show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    String? previewText,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.materialL10n.modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return SuccessDialog(
          title: title,
          message: message,
          previewText: previewText,
          icon: icon,
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

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _iconController.forward();

    // Автозакрытие
    Future.delayed(widget.autoCloseDuration, () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final successColor = themeColors.success;

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
              ScaleTransition(
                scale: _iconScale,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: successColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: successColor, size: 32),
                ),
              ),
              AppSpacer.p16,
              Text(
                widget.title,
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacer.p8,
              Text(
                widget.message,
                style: textTheme.bodyMedium?.copyWith(
                  color: themeColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.previewText != null &&
                  widget.previewText!.isNotEmpty) ...[
                AppSpacer.p16,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.p12),
                  decoration: BoxDecoration(
                    color: themeColors.bgTertiary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: Text(
                    _truncateText(widget.previewText!, 100),
                    style: textTheme.bodySmall?.copyWith(
                      color: themeColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              AppSpacer.p24,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successColor,
                  ),
                  child: const Text('Понятно'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
