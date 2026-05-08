import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';
import 'package:voice_notes/core/adaptive/window/adaptive_content_width.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/export/app_data_export_service.dart';
import 'package:voice_notes/core/packages/export/app_data_share_service.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/queue/screens/queue_management_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/widgets/export_data_sheet.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/widgets/import_data_sheet/import_data_sheet.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/widgets/settings_row.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/widgets/settings_section.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/screens/storage_screen.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/language_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/theme_dialog.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  static void go(BuildContext context) {
    context.go(AppRoutes.settings.general);
  }

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final RecordingPreferences _recordingPrefs = getIt<RecordingPreferences>();

  late bool _keepOriginals = _recordingPrefs.keepOriginals;

  bool _autoTags = false;

  Future<void> _onKeepOriginalsChanged(bool value) async {
    setState(() => _keepOriginals = value);
    await _recordingPrefs.setKeepOriginals(value);
  }

  String _languageDisplayName(Locale locale) {
    final name = LanguageOption.all
        .firstWhereOrNull((option) => option.code == locale.languageCode)
        ?.name;

    return name ?? locale.languageCode;
  }

  Future<void> _onThemeTap() async {
    final themeCubit = context.read<ThemeCubit>();

    await ThemeDialog.show(
      context: context,
      currentMode: themeCubit.state.mode,
      onSave: themeCubit.setTheme,
    );
  }

  Future<void> _onAppLanguageTap() async {
    final localeCubit = context.read<LocaleCubit>();

    await LanguageDialog.show(
      context: context,
      currentLanguage: localeCubit.state.locale.languageCode,
      onSave: (code) => localeCubit.setLocale(Locale(code)),
    );
  }

  Future<void> _onExportTap() async {
    await ExportDataSheet.show(
      context,
      exportService: getIt<AppDataExportService>(),
      shareService: getIt<AppDataShareService>(),
    );
  }

  Future<void> _onImportTap() async {
    await ImportDataSheet.show(context);
  }

  /// Количество заметок во всех «активных» состояниях пайплайна:
  /// queued + transcribing + failed + cancelled. Используется бейджем очереди
  /// в общих настройках, чтобы показать реальный backlog, а не только провалы.
  Stream<int> _queueBadgeStream(NoteRepository repo) {
    return Rx.combineLatestList<List<NoteEntity>>([
          repo.watchQueued(),
          repo.watchTranscribing(),
          repo.watchFailed(),
          repo.watchCancelled(),
        ])
        .map((lists) => lists.fold<int>(0, (acc, l) => acc + l.length))
        .distinct();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.screenPadding),
      child: AdaptiveContentWidth(
        maxWidth: 760,
        child: Column(
          children: [
            SettingsSection(
              title: l10n.settingsSectionRecording,
              children: [
                SettingsRow(
                  icon: Icons.audiotrack_outlined,
                  title: l10n.settingsKeepOriginalsTitle,
                  subtitle: l10n.settingsKeepOriginalsSubtitle,
                  trailing: SettingsToggle(
                    value: _keepOriginals,
                    onChanged: _onKeepOriginalsChanged,
                  ),
                  showDivider: false,
                ),
              ],
            ),
            AppSpacer.p20,
            SettingsSection(
              title: l10n.settingsSectionTranscription,
              children: [
                SettingsRow(
                  icon: Icons.tag,
                  title: l10n.settingsAutoTags,
                  subtitle: l10n.settingsAutoTagsSubtitle,
                  trailing: SettingsToggle(
                    value: _autoTags,
                    onChanged: (value) => setState(() => _autoTags = value),
                  ),
                  isEnabled: false,
                  showDivider: false,
                ),
              ],
            ),
            AppSpacer.p20,
            SettingsSection(
              title: l10n.settingsSectionInterface,
              children: [
                BlocSelector<ThemeCubit, ThemeState, AppThemeMode>(
                  selector: (state) => state.mode,
                  builder: (context, mode) {
                    final themeName = mode == AppThemeMode.light
                        ? l10n.settingsThemeLight
                        : l10n.settingsThemeDark;

                    return SettingsRow(
                      icon: Icons.dark_mode_outlined,
                      title: l10n.settingsTheme,
                      trailing: SettingsChevron(value: themeName),
                      onTap: _onThemeTap,
                    );
                  },
                ),
                BlocSelector<LocaleCubit, LocaleState, Locale>(
                  selector: (state) => state.locale,
                  builder: (context, locale) {
                    final appLanguage = _languageDisplayName(locale);

                    return SettingsRow(
                      icon: Icons.translate,
                      title: l10n.settingsAppLanguage,
                      trailing: SettingsChevron(value: appLanguage),
                      onTap: _onAppLanguageTap,
                      showDivider: false,
                    );
                  },
                ),
              ],
            ),
            AppSpacer.p20,
            SettingsSection(
              title: l10n.settingsSectionNotifications,
              children: [
                SettingsRow(
                  icon: Icons.notifications_outlined,
                  title: l10n.settingsSectionNotifications,
                  subtitle: l10n.settingsNotificationsSubtitle,
                  trailing: const SettingsToggle(value: false),
                  isEnabled: false,
                  showDivider: false,
                ),
              ],
            ),
            AppSpacer.p20,
            SettingsSection(
              title: l10n.queueSettingsSection,
              children: [
                StreamBuilder<int>(
                  stream: _queueBadgeStream(getIt<NoteRepository>()),
                  initialData: 0,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    final value = count > 0 ? '$count' : null;

                    return SettingsRow(
                      icon: Icons.queue_outlined,
                      title: l10n.queueSettingsRowTitle,
                      trailing: SettingsChevron(value: value),
                      onTap: () => QueueManagementScreen.go(context),
                      showDivider: false,
                    );
                  },
                ),
              ],
            ),
            AppSpacer.p20,
            SettingsSection(
              title: l10n.settingsSectionData,
              children: [
                SettingsRow(
                  icon: Icons.storage_rounded,
                  title: l10n.settingsStorageEntryTitle,
                  trailing: const SettingsChevron(),
                  onTap: () => StorageScreen.go(context),
                ),
                SettingsRow(
                  icon: Icons.upload_outlined,
                  title: l10n.settingsExportData,
                  trailing: const SettingsChevron(),
                  onTap: _onExportTap,
                ),
                SettingsRow(
                  icon: Icons.download_outlined,
                  title: l10n.settingsImportData,
                  trailing: const SettingsChevron(),
                  onTap: _onImportTap,
                  showDivider: false,
                ),
              ],
            ),
            AppSpacer.p40,
          ],
        ),
      ),
    );
  }
}
