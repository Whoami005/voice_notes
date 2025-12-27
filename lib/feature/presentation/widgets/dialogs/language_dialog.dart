import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

class LanguageOption {
  final String code;
  final String name;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });

  static const ru = LanguageOption(code: 'ru', name: 'Русский', flag: '🇷🇺');
  static const en = LanguageOption(code: 'en', name: 'English', flag: '🇺🇸');

  static const List<LanguageOption> all = [ru, en];
}

class LanguageDialog extends StatelessWidget {
  final String currentLanguage;

  const LanguageDialog({required this.currentLanguage, super.key});

  static Future<String?> show({
    required BuildContext context,
    required String currentLanguage,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return LanguageDialog(currentLanguage: currentLanguage);
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
                'Язык интерфейса',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              AppSpacer.p20,
              ...LanguageOption.all.map((option) {
                final isSelected = option.code == currentLanguage;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p12),
                  child: _LanguageItem(
                    option: option,
                    isSelected: isSelected,
                    onTap: () => Navigator.of(context).pop(option.code),
                  ),
                );
              }),
              AppSpacer.p8,
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена'),
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
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          color: isSelected ? themeColors.accentMuted : themeColors.bgTertiary,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: isSelected ? themeColors.accentPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(option.flag, style: const TextStyle(fontSize: 24)),
            AppSpacer.p12,
            Expanded(
              child: Text(
                option.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: themeColors.accentPrimary,
                size: AppSizes.iconMedium,
              ),
          ],
        ),
      ),
    );
  }
}
