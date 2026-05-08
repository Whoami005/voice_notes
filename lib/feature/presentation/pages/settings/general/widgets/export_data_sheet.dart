import 'package:flutter/material.dart';
import 'package:voice_notes/common/utils/format_bytes.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/export/app_data_export_models.dart';
import 'package:voice_notes/core/packages/export/app_data_export_service.dart';
import 'package:voice_notes/core/packages/export/app_data_share_service.dart';
import 'package:voice_notes/feature/domain/enums/share_result_status_enum.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/widgets/settings_row.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:voice_notes/feature/presentation/widgets/toasts/app_toast.dart';

class ExportDataSheet extends StatefulWidget {
  final AppDataExportService exportService;
  final AppDataShareService shareService;

  const ExportDataSheet({
    required this.exportService,
    required this.shareService,
    super.key,
  });

  static Future<void> show(
    BuildContext context, {
    required AppDataExportService exportService,
    required AppDataShareService shareService,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      title: context.l10n.settingsExportSheetTitle,
      useRootNavigator: true,
      child: ExportDataSheet(
        exportService: exportService,
        shareService: shareService,
      ),
    );
  }

  @override
  State<ExportDataSheet> createState() => _ExportDataSheetState();
}

class _ExportDataSheetState extends State<ExportDataSheet> {
  late final Future<AppDataExportSummary> _summaryFuture;

  bool _includeAudio = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = widget.exportService.getSummary();
  }

  Future<void> _onCreateBackup() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final artifact = await widget.exportService.createBackup(
        options: AppDataExportOptions(includeAudio: _includeAudio),
      );

      if (!mounted) return;

      final status = await widget.shareService.shareBackup(
        context: context,
        artifact: artifact,
      );

      if (mounted) {
        switch (status) {
          case ShareResultStatusEnum.success:
            AppToast.success(
              context,
              message: context.l10n.settingsExportSuccess,
            );
            Navigator.of(context).pop();
          case ShareResultStatusEnum.unavailable:
            AppToast.error(context, message: context.l10n.errorGenericMessage);
          case ShareResultStatusEnum.dismissed:
            break;
        }
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, message: context.l10n.errorGenericMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsExportDescription,
          style: textTheme.bodyMedium?.copyWith(
            color: themeColors.textSecondary,
          ),
        ),
        AppSpacer.p16,
        FutureBuilder<AppDataExportSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            final summary = snapshot.data;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.p16),
              decoration: BoxDecoration(
                color: themeColors.bgTertiary,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: themeColors.borderPrimary),
              ),
              child: switch (snapshot.connectionState) {
                ConnectionState.waiting => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.p8),
                    child: CircularProgressIndicator(),
                  ),
                ),
                _ when summary != null => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsExportNotesCount(summary.notesCount),
                      style: textTheme.titleMedium?.copyWith(
                        color: themeColors.textPrimary,
                      ),
                    ),
                    AppSpacer.p8,
                    Text(
                      summary.audioCount > 0
                          ? l10n.settingsExportAudioSummary(
                              l10n.storageRecordingsCount(summary.audioCount),
                              BytesFormatter.format(summary.audioBytes),
                            )
                          : l10n.settingsExportNoAudio,
                      style: textTheme.bodySmall?.copyWith(
                        color: themeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _ => Text(
                  l10n.errorGenericMessage,
                  style: textTheme.bodySmall?.copyWith(
                    color: themeColors.error,
                  ),
                ),
              },
            );
          },
        ),
        AppSpacer.p16,
        Container(
          decoration: BoxDecoration(
            color: themeColors.bgTertiary,
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(color: themeColors.borderPrimary),
          ),
          child: SettingsRow(
            icon: Icons.audiotrack_outlined,
            title: l10n.settingsExportIncludeAudioTitle,
            subtitle: l10n.settingsExportIncludeAudioSubtitle,
            trailing: SettingsToggle(
              key: const Key('export-sheet-include-audio'),
              value: _includeAudio,
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _includeAudio = value),
            ),
            showDivider: false,
          ),
        ),
        AppSpacer.p16,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.p16),
          decoration: BoxDecoration(
            color: themeColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            border: Border.all(
              color: themeColors.warning.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                size: AppSizes.iconMedium,
                color: themeColors.warning,
              ),
              AppSpacer.p12,
              Expanded(
                child: Text(
                  l10n.settingsExportPrivacyWarning,
                  style: textTheme.bodySmall?.copyWith(
                    color: themeColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacer.p20,
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('export-sheet-create'),
            onPressed: _isSubmitting ? null : _onCreateBackup,
            child: _isSubmitting
                ? const SizedBox(
                    width: AppSizes.iconMedium,
                    height: AppSizes.iconMedium,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.settingsExportCreateBackup),
          ),
        ),
      ],
    );
  }
}
