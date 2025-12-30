import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/presentation/pages/settings/widgets/model_card.dart';
import 'package:voice_notes/feature/presentation/pages/settings/widgets/settings_row.dart';
import 'package:voice_notes/feature/presentation/pages/settings/widgets/settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Mock settings state
  bool _autoSave = true;
  bool _vadEnabled = true;
  bool _autoTags = false;
  String _recordingQuality = 'Высокое';
  String _defaultLanguage = 'Русский';
  String _theme = 'Системная';
  String _appLanguage = 'Русский';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: themeColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Настройки',
          style: AppTypography.h2.copyWith(color: themeColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Основные'),
            Tab(text: 'Модели'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GeneralTab(
            autoSave: _autoSave,
            vadEnabled: _vadEnabled,
            autoTags: _autoTags,
            recordingQuality: _recordingQuality,
            defaultLanguage: _defaultLanguage,
            theme: _theme,
            appLanguage: _appLanguage,
            onAutoSaveChanged: (value) => setState(() => _autoSave = value),
            onVadChanged: (value) => setState(() => _vadEnabled = value),
            onAutoTagsChanged: (value) => setState(() => _autoTags = value),
            onRecordingQualityTap: _onRecordingQualityTap,
            onDefaultLanguageTap: _onDefaultLanguageTap,
            onThemeTap: _onThemeTap,
            onAppLanguageTap: _onAppLanguageTap,
            onExportTap: _onExportTap,
            onClearCacheTap: _onClearCacheTap,
          ),
          _ModelsTab(
            models: AsrModelEntity.availableModels,
            onUseModel: _onUseModel,
            onDownloadModel: _onDownloadModel,
            onDeleteModel: _onDeleteModel,
          ),
        ],
      ),
    );
  }

  void _onRecordingQualityTap() {
    // TODO: Show quality picker
  }

  void _onDefaultLanguageTap() {
    // TODO: Show language dialog
  }

  void _onThemeTap() {
    // TODO: Show theme picker
  }

  void _onAppLanguageTap() {
    // TODO: Show language dialog
  }

  void _onExportTap() {
    // TODO: Export data
  }

  void _onClearCacheTap() {
    // TODO: Show confirm dialog
  }

  void _onUseModel(AsrModelEntity model) {
    // TODO: Set active model
  }

  void _onDownloadModel(AsrModelEntity model) {
    // TODO: Download model
  }

  void _onDeleteModel(AsrModelEntity model) {
    // TODO: Delete model
  }
}

class _GeneralTab extends StatelessWidget {
  final bool autoSave;
  final bool vadEnabled;
  final bool autoTags;
  final String recordingQuality;
  final String defaultLanguage;
  final String theme;
  final String appLanguage;
  final ValueChanged<bool> onAutoSaveChanged;
  final ValueChanged<bool> onVadChanged;
  final ValueChanged<bool> onAutoTagsChanged;
  final VoidCallback onRecordingQualityTap;
  final VoidCallback onDefaultLanguageTap;
  final VoidCallback onThemeTap;
  final VoidCallback onAppLanguageTap;
  final VoidCallback onExportTap;
  final VoidCallback onClearCacheTap;

  const _GeneralTab({
    required this.autoSave,
    required this.vadEnabled,
    required this.autoTags,
    required this.recordingQuality,
    required this.defaultLanguage,
    required this.theme,
    required this.appLanguage,
    required this.onAutoSaveChanged,
    required this.onVadChanged,
    required this.onAutoTagsChanged,
    required this.onRecordingQualityTap,
    required this.onDefaultLanguageTap,
    required this.onThemeTap,
    required this.onAppLanguageTap,
    required this.onExportTap,
    required this.onClearCacheTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.screenPadding),
      child: Column(
        children: [
          SettingsSection(
            title: 'Запись',
            children: [
              SettingsRow(
                icon: Icons.save_outlined,
                title: 'Авто-сохранение',
                subtitle: 'Сохранять записи автоматически',
                trailing: SettingsToggle(
                  value: autoSave,
                  onChanged: onAutoSaveChanged,
                ),
              ),
              SettingsRow(
                icon: Icons.tune,
                title: 'Качество записи',
                trailing: SettingsChevron(value: recordingQuality),
                onTap: onRecordingQualityTap,
              ),
              SettingsRow(
                icon: Icons.mic_off_outlined,
                title: 'VAD',
                subtitle: 'Авто-стоп при тишине',
                trailing: SettingsToggle(
                  value: vadEnabled,
                  onChanged: onVadChanged,
                ),
                showDivider: false,
              ),
            ],
          ),
          AppSpacer.p20,
          SettingsSection(
            title: 'Транскрипция',
            children: [
              SettingsRow(
                icon: Icons.language,
                title: 'Язык по умолчанию',
                trailing: SettingsChevron(value: defaultLanguage),
                onTap: onDefaultLanguageTap,
              ),
              SettingsRow(
                icon: Icons.tag,
                title: 'Авто-теги',
                subtitle: 'Автоматически добавлять теги',
                trailing: SettingsToggle(
                  value: autoTags,
                  onChanged: onAutoTagsChanged,
                ),
                showDivider: false,
              ),
            ],
          ),
          AppSpacer.p20,
          SettingsSection(
            title: 'Интерфейс',
            children: [
              SettingsRow(
                icon: Icons.dark_mode_outlined,
                title: 'Тема',
                trailing: SettingsChevron(value: theme),
                onTap: onThemeTap,
              ),
              SettingsRow(
                icon: Icons.translate,
                title: 'Язык приложения',
                trailing: SettingsChevron(value: appLanguage),
                onTap: onAppLanguageTap,
                showDivider: false,
              ),
            ],
          ),
          AppSpacer.p20,
          const SettingsSection(
            title: 'Уведомления',
            children: [
              SettingsRow(
                icon: Icons.notifications_outlined,
                title: 'Уведомления',
                subtitle: 'Скоро',
                trailing: SettingsToggle(value: false),
                isEnabled: false,
                showDivider: false,
              ),
            ],
          ),
          AppSpacer.p20,
          SettingsSection(
            title: 'Данные',
            children: [
              SettingsRow(
                icon: Icons.upload_outlined,
                title: 'Экспорт данных',
                trailing: const SettingsChevron(),
                onTap: onExportTap,
              ),
              SettingsRow(
                icon: Icons.delete_sweep_outlined,
                title: 'Очистка кэша',
                subtitle: 'Освободить место на устройстве',
                trailing: const SettingsChevron(),
                onTap: onClearCacheTap,
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

class _ModelsTab extends StatelessWidget {
  final List<AsrModelEntity> models;
  final ValueChanged<AsrModelEntity> onUseModel;
  final ValueChanged<AsrModelEntity> onDownloadModel;
  final ValueChanged<AsrModelEntity> onDeleteModel;

  const _ModelsTab({
    required this.models,
    required this.onUseModel,
    required this.onDownloadModel,
    required this.onDeleteModel,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final activeModel = models.firstWhere(
      (m) => m.isSelected,
      orElse: () => models.first,
    );
    final otherModels = models.where((m) => !m.isSelected).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'АКТИВНАЯ МОДЕЛЬ',
            style: AppTypography.overline.copyWith(
              color: themeColors.textTertiary,
            ),
          ),
          AppSpacer.p8,
          ModelCard(
            model: activeModel,
            onUse: () => onUseModel(activeModel),
            onDownload: () => onDownloadModel(activeModel),
            onDelete: () => onDeleteModel(activeModel),
          ),
          AppSpacer.p24,
          Text(
            'ДОСТУПНЫЕ МОДЕЛИ',
            style: AppTypography.overline.copyWith(
              color: themeColors.textTertiary,
            ),
          ),
          AppSpacer.p8,
          ...otherModels.map(
            (model) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.p12),
              child: ModelCard(
                model: model,
                onUse: () => onUseModel(model),
                onDownload: () => onDownloadModel(model),
                onDelete: () => onDeleteModel(model),
              ),
            ),
          ),
          AppSpacer.p40,
        ],
      ),
    );
  }
}
