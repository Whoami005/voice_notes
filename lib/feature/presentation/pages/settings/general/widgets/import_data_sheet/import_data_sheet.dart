import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/import_data_sheet_error_l10n.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/backup/app_data_backup_models.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/import/app_data_import_service.dart';
import 'package:voice_notes/core/packages/import/backup_file_picker_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/state/effect/effect_listener.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/logic/import_data_sheet_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/widgets/import_data_sheet/src/import_data_sheet_cards.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/widgets/import_data_sheet/src/import_data_sheet_preview_card.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/toasts/app_toast.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class ImportDataSheet extends StatefulWidget {
  const ImportDataSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.showSliver<void>(
      context: context,
      title: context.l10n.settingsImportSheetTitle,
      useRootNavigator: true,
      sliver: BlocProvider(
        create: (_) => ImportDataSheetCubit(
          importService: getIt<AppDataImportService>(),
          filePickerService: getIt<BackupFilePickerService>(),
          queueController: getIt<TranscriptionQueueController>(),
        ),
        child: const ImportDataSheet(),
      ),
    );
  }

  @override
  State<ImportDataSheet> createState() => _ImportDataSheetState();
}

class _ImportDataSheetState extends State<ImportDataSheet> {
  Future<void> _onSubmitPressed(BuildContext context) async {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.settingsImportConfirmTitle,
      message: l10n.settingsImportConfirmMessage,
      confirmText: l10n.settingsImportConfirmImport,
      cancelText: l10n.dialogCancel,
      confirmColor: themeColors.error,
      icon: Icons.warning_amber_rounded,
    );

    if (confirmed != true || !context.mounted) return;

    final result = await context.read<ImportDataSheetCubit>().submitImport();
    if (result == null || !context.mounted) return;

    await _restoreSettings(result.settings);

    if (!context.mounted) return;

    AppToast.success(context, message: l10n.settingsImportSuccess);
    if (result.hasWarnings) {
      AppToast.warning(
        context,
        message: l10n.settingsImportSuccessWithWarnings(result.warningsCount),
      );
    }

    Navigator.of(context).pop();
  }

  Future<void> _restoreSettings(AppDataBackupSettings settings) async {
    await _restoreTheme(settings.themeMode);
    await _restoreLocale(settings.localeCode);
    await _restoreRecordingSettings(settings.recording.keepOriginals);
  }

  Future<void> _restoreTheme(String themeModeKey) async {
    final themeCubit = context.read<ThemeCubit>();

    final themeMode = AppThemeMode.fromString(themeModeKey);
    if (themeMode != null) await themeCubit.setTheme(themeMode);
  }

  Future<void> _restoreLocale(String localeCode) async {
    final localeCubit = context.read<LocaleCubit>();

    final supportedLocale = AppLocalizations.supportedLocales.firstWhere(
      (locale) => locale.languageCode == localeCode,
      orElse: () => AppLocalizations.supportedLocales.first,
    );

    if (supportedLocale.languageCode == localeCode) {
      await localeCubit.setLocale(Locale(localeCode));
    }
  }

  Future<void> _restoreRecordingSettings(bool keepOriginals) async {
    try {
      await getIt<RecordingPreferences>().setKeepOriginals(keepOriginals);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return EffectListener<ImportDataSheetCubit, ImportDataSheetEffect>(
      listener: (context, effect) {
        switch (effect) {
          case ShowImportErrorEffect(:final error):
            AppToast.error(context, message: error.message(context.l10n));
        }
      },
      child: BlocBuilder<ImportDataSheetCubit, ImportDataSheetState>(
        builder: (context, state) {
          final cubit = context.read<ImportDataSheetCubit>();

          return SliverList.list(
            children: [
              Text(
                context.l10n.settingsImportDescription,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.themeColors.textSecondary,
                ),
              ),
              AppSpacer.p16,
              if (state.isQueueBusy) ...[
                ImportQueueWarningCard(
                  count: state.activeQueueCount,
                  onOpenQueue: () {
                    context.push(AppRoutes.settings.queue);
                  },
                ),
                AppSpacer.p16,
              ],
              ImportFilePickerCard(state: state, onPick: cubit.pickBackupFile),
              if (state.preview != null) ...[
                AppSpacer.p16,
                ImportPreviewCard(preview: state.preview!),
              ],
              AppSpacer.p16,
              const ImportDestructiveWarningCard(),
              AppSpacer.p20,
              ImportSubmitButton(
                canSubmit: state.canSubmit,
                isImporting: state.isImporting,
                onSubmit: () => _onSubmitPressed(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
