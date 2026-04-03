import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';

class ThemeDialog extends StatelessWidget {
  final AppThemeMode currentMode;

  const ThemeDialog({required this.currentMode, super.key});

  static Future<AppThemeMode?> show({
    required BuildContext context,
    required AppThemeMode currentMode,
  }) {
    return showGeneralDialog<AppThemeMode>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.materialL10n.modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return ThemeDialog(currentMode: currentMode);
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.themeDialogTitle,
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacer.p20,
              for (final mode in AppThemeMode.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p12),
                  child: _ThemeItem(
                    mode: mode,
                    isSelected: mode == currentMode,
                    onTap: () => context.router.pop(mode),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  final AppThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeItem({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon => switch (mode) {
    AppThemeMode.light => Icons.light_mode_outlined,
    AppThemeMode.dark => Icons.dark_mode_outlined,
  };

  String _label(BuildContext context) => switch (mode) {
    AppThemeMode.light => context.l10n.settingsThemeLight,
    AppThemeMode.dark => context.l10n.settingsThemeDark,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? themeColors.accentMuted : themeColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isSelected ? themeColors.accentPrimary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        onTap: onTap,
        leading: Icon(
          _icon,
          size: 24,
          color: isSelected
              ? themeColors.accentPrimary
              : themeColors.textSecondary,
        ),
        title: Text(
          _label(context),
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: themeColors.accentPrimary,
                size: AppSizes.iconMedium,
              )
            : null,
      ),
    );
  }
}
