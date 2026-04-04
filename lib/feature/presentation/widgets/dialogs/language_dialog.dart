import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';

class LanguageOption {
  final String code;
  final String name;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });

  static const en = LanguageOption(code: 'en', name: 'English', flag: '🇺🇸');
  static const ru = LanguageOption(code: 'ru', name: 'Русский', flag: '🇷🇺');

  static const List<LanguageOption> all = [en, ru];
}

class LanguageDialog extends StatefulWidget {
  final String currentLanguage;
  final Future<bool> Function(String code) onSave;

  const LanguageDialog({
    required this.currentLanguage,
    required this.onSave,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentLanguage,
    required Future<bool> Function(String code) onSave,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.materialL10n.modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return LanguageDialog(currentLanguage: currentLanguage, onSave: onSave);
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
  State<LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<LanguageDialog> {
  Future<void> _onSelect(String code) async {
    if (code == widget.currentLanguage) {
      context.router.pop();
      return;
    }

    final success = await widget.onSave(code);

    if (!mounted) return;

    success ? context.router.pop() : ErrorDialog.showUnknownError(context);
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
                context.l10n.languageDialogTitle,
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacer.p20,
              for (final option in LanguageOption.all)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p12),
                  child: _LanguageItem(
                    option: option,
                    displayName: option.name,
                    isSelected: option.code == widget.currentLanguage,
                    onTap: () => _onSelect(option.code),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final LanguageOption option;
  final String displayName;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.option,
    required this.displayName,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? themeColors.accentMuted : themeColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isSelected ? themeColors.accentPrimary : AppColors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        onTap: onTap,
        leading: Text(option.flag, style: const TextStyle(fontSize: 24)),
        title: Text(
          displayName,
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
