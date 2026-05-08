import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/logic/import_data_sheet_cubit.dart';

class ImportQueueWarningCard extends StatelessWidget {
  final int count;
  final VoidCallback onOpenQueue;

  const ImportQueueWarningCard({
    required this.count,
    required this.onOpenQueue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: themeColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: themeColors.warning.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.queue_outlined,
                color: themeColors.warning,
                size: AppSizes.iconMedium,
              ),
              AppSpacer.p12,
              Expanded(
                child: Text(
                  l10n.settingsImportQueueWarning(count),
                  style: textTheme.bodyMedium?.copyWith(
                    color: themeColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacer.p12,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('import-sheet-open-queue'),
              onPressed: onOpenQueue,
              child: Text(l10n.settingsImportOpenQueue),
            ),
          ),
        ],
      ),
    );
  }
}

class ImportFilePickerCard extends StatelessWidget {
  final ImportDataSheetState state;
  final VoidCallback onPick;

  const ImportFilePickerCard({
    required this.state,
    required this.onPick,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final fileName = state.selectedFile?.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: themeColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsImportFileTitle,
            style: textTheme.titleMedium?.copyWith(
              color: themeColors.textPrimary,
            ),
          ),
          AppSpacer.p8,
          Text(
            fileName == null
                ? l10n.settingsImportFileSubtitle
                : l10n.settingsImportFileSelected(fileName),
            style: textTheme.bodySmall?.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
          AppSpacer.p12,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('import-sheet-choose-file'),
              onPressed: state.isBusy ? null : onPick,
              icon: state.isPicking || state.isInspecting
                  ? const SizedBox(
                      width: AppSizes.iconSmall,
                      height: AppSizes.iconSmall,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file_outlined),
              label: Text(
                fileName == null
                    ? l10n.settingsImportChooseFile
                    : l10n.settingsImportChooseFileAgain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImportDestructiveWarningCard extends StatelessWidget {
  const ImportDestructiveWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: themeColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: themeColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: themeColors.error,
            size: AppSizes.iconMedium,
          ),
          AppSpacer.p12,
          Expanded(
            child: Text(
              l10n.settingsImportWarning,
              style: textTheme.bodySmall?.copyWith(
                color: themeColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImportSubmitButton extends StatelessWidget {
  final bool canSubmit;
  final bool isImporting;
  final VoidCallback onSubmit;

  const ImportSubmitButton({
    required this.canSubmit,
    required this.isImporting,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: const Key('import-sheet-submit'),
        onPressed: canSubmit ? onSubmit : null,
        child: isImporting
            ? const SizedBox(
                width: AppSizes.iconMedium,
                height: AppSizes.iconMedium,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(context.l10n.settingsImportAction),
      ),
    );
  }
}
