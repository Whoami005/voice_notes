import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmDialog({
    required this.title,
    required this.message,
    super.key,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.icon,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    IconData? icon,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.materialL10n.modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ConfirmDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          confirmColor: confirmColor,
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
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final effectiveConfirmColor = confirmColor ?? themeColors.error;

    final l10n = context.l10n;
    final effectiveConfirmText = confirmText ?? l10n.dialogConfirm;
    final effectiveCancelText = cancelText ?? l10n.dialogCancel;

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
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: effectiveConfirmColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: effectiveConfirmColor,
                    size: AppSizes.iconMedium,
                  ),
                ),
                AppSpacer.p16,
              ],
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
              AppSpacer.p24,
              Row(
                spacing: AppSizes.p8,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        effectiveCancelText,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: effectiveConfirmColor,
                      ),
                      child: Text(
                        effectiveConfirmText,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
