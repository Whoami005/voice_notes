import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/import/app_data_import_models.dart';

class ImportPreviewCard extends StatelessWidget {
  final AppDataImportPreview preview;

  const ImportPreviewCard({required this.preview, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final exportedAt = DateTime.tryParse(preview.exportedAt)?.toLocal();
    final format = DateFormat('yyyy-MM-dd HH:mm');

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
            l10n.settingsImportPreviewTitle,
            style: textTheme.titleMedium?.copyWith(
              color: themeColors.textPrimary,
            ),
          ),
          AppSpacer.p12,
          _ImportPreviewRow(
            label: l10n.settingsImportPreviewFile,
            value: preview.fileName,
          ),
          _ImportPreviewRow(
            label: l10n.settingsImportPreviewExportedAt,
            value: exportedAt == null
                ? preview.exportedAt
                : format.format(exportedAt),
          ),
          _ImportPreviewRow(
            label: l10n.settingsImportPreviewNotes,
            value: '${preview.notesCount}',
          ),
          _ImportPreviewRow(
            label: l10n.settingsImportPreviewFolders,
            value: '${preview.foldersCount}',
          ),
          _ImportPreviewRow(
            label: l10n.settingsImportPreviewTags,
            value: '${preview.tagsCount}',
          ),
          _ImportPreviewRow(
            label: l10n.settingsImportPreviewAudio,
            value: preview.includesAudio
                ? l10n.settingsImportPreviewAudioIncluded(
                    preview.audioFilesCount,
                  )
                : l10n.settingsImportPreviewAudioNotIncluded,
          ),
          if (preview.warningsCount > 0) ...[
            AppSpacer.p8,
            Text(
              l10n.settingsImportPreviewWarnings(preview.warningsCount),
              style: textTheme.bodySmall?.copyWith(color: themeColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportPreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ImportPreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p8),
      child: Row(
        spacing: AppSizes.p8,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: themeColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 3,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
