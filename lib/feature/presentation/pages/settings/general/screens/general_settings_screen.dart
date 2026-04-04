import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/widgets/settings_row.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/widgets/settings_section.dart';
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
  // Mock settings state
  bool _autoSave = true;
  bool _vadEnabled = true;
  bool _autoTags = false;
  String _recordingQuality = 'Высокое';
  String _defaultLanguage = 'Русский';

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

  void _onRecordingQualityTap() {
    // TODO: Show quality picker
  }

  void _onDefaultLanguageTap() {
    // TODO: Show language dialog
  }

  void _onExportTap() {
    // TODO: Export data
  }

  void _onClearCacheTap() {
    // TODO(settings): Show confirm dialog
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.screenPadding),
      child: Column(
        children: [
          SettingsSection(
            title: l10n.settingsSectionRecording,
            children: [
              SettingsRow(
                icon: Icons.save_outlined,
                title: l10n.settingsAutoSaveTitle,
                subtitle: l10n.settingsAutoSaveSubtitle,
                trailing: SettingsToggle(
                  value: _autoSave,
                  onChanged: (value) => setState(() => _autoSave = value),
                ),
                isEnabled: false,
              ),
              SettingsRow(
                icon: Icons.tune,
                title: l10n.settingsRecordingQuality,
                trailing: SettingsChevron(value: _recordingQuality),
                onTap: _onRecordingQualityTap,
                isEnabled: false,
              ),
              SettingsRow(
                icon: Icons.mic_off_outlined,
                title: l10n.settingsVadTitle,
                subtitle: l10n.settingsVadSubtitle,
                trailing: SettingsToggle(
                  value: _vadEnabled,
                  onChanged: (value) => setState(() => _vadEnabled = value),
                ),
                isEnabled: false,
                showDivider: false,
              ),
            ],
          ),
          AppSpacer.p20,
          SettingsSection(
            title: l10n.settingsSectionTranscription,
            children: [
              SettingsRow(
                icon: Icons.language,
                title: l10n.settingsDefaultLanguage,
                trailing: SettingsChevron(value: _defaultLanguage),
                onTap: _onDefaultLanguageTap,
                isEnabled: false,
              ),
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
            title: l10n.settingsSectionData,
            children: [
              SettingsRow(
                icon: Icons.upload_outlined,
                title: l10n.settingsExportData,
                trailing: const SettingsChevron(),
                onTap: _onExportTap,
                isEnabled: false,
              ),
              SettingsRow(
                icon: Icons.delete_sweep_outlined,
                title: l10n.settingsClearCache,
                subtitle: l10n.settingsClearCacheSubtitle,
                trailing: const SettingsChevron(),
                onTap: _onClearCacheTap,
                isEnabled: false,
                showDivider: false,
              ),
            ],
          ),
          AppSpacer.p40,
        ],
      ),
    );
  }
}
