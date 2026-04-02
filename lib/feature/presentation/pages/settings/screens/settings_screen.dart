import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/state/async/async_state_widgets.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/logic/models_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/widgets/model_card.dart';
import 'package:voice_notes/feature/presentation/pages/settings/widgets/settings_row.dart';
import 'package:voice_notes/feature/presentation/pages/settings/widgets/settings_section.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/language_dialog.dart';

class SettingsScreen extends StatefulWidget implements AppRouteWrapper {
  const SettingsScreen({super.key});

  /// Навигация на экран настроек
  static void go(BuildContext context) {
    context.go(AppRoutes.settings.root);
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => ModelsCubit(
        repository: getIt<ModelRepository>(),
        asrService: getIt<AsrService>(),
      ),
      child: this,
    );
  }

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
  String _theme = 'Темная';

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
          context.l10n.settingsTitle,
          style: AppTypography.h2.copyWith(color: themeColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.settingsTabGeneral),
            Tab(text: context.l10n.settingsTabModels),
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
            onAutoSaveChanged: (value) => setState(() => _autoSave = value),
            onVadChanged: (value) => setState(() => _vadEnabled = value),
            onAutoTagsChanged: (value) => setState(() => _autoTags = value),
            onRecordingQualityTap: _onRecordingQualityTap,
            onDefaultLanguageTap: _onDefaultLanguageTap,
            onThemeTap: _onThemeTap,
            onExportTap: _onExportTap,
            onClearCacheTap: _onClearCacheTap,
          ),
          const _ModelsTab(),
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

  void _onExportTap() {
    // TODO: Export data
  }

  void _onClearCacheTap() {
    // TODO(settings): Show confirm dialog
  }
}

class _GeneralTab extends StatefulWidget {
  final bool autoSave;
  final bool vadEnabled;
  final bool autoTags;
  final String recordingQuality;
  final String defaultLanguage;
  final String theme;
  final ValueChanged<bool> onAutoSaveChanged;
  final ValueChanged<bool> onVadChanged;
  final ValueChanged<bool> onAutoTagsChanged;
  final VoidCallback onRecordingQualityTap;
  final VoidCallback onDefaultLanguageTap;
  final VoidCallback onThemeTap;
  final VoidCallback onExportTap;
  final VoidCallback onClearCacheTap;

  const _GeneralTab({
    required this.autoSave,
    required this.vadEnabled,
    required this.autoTags,
    required this.recordingQuality,
    required this.defaultLanguage,
    required this.theme,
    required this.onAutoSaveChanged,
    required this.onVadChanged,
    required this.onAutoTagsChanged,
    required this.onRecordingQualityTap,
    required this.onDefaultLanguageTap,
    required this.onThemeTap,
    required this.onExportTap,
    required this.onClearCacheTap,
  });

  @override
  State<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<_GeneralTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _languageDisplayName(Locale locale) {
    final name = LanguageOption.all
        .firstWhereOrNull((option) => option.code == locale.languageCode)
        ?.name;

    return name ?? locale.languageCode;
  }

  Future<void> _onAppLanguageTap() async {
    final localeCubit = context.read<LocaleCubit>();
    final currentCode = localeCubit.state.locale.languageCode;

    final selectedCode = await LanguageDialog.show(
      context: context,
      currentLanguage: currentCode,
    );

    if (selectedCode != null && selectedCode != currentCode) {
      await localeCubit.setLocale(Locale(selectedCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  value: widget.autoSave,
                  onChanged: widget.onAutoSaveChanged,
                ),
                isEnabled: false,
              ),
              SettingsRow(
                icon: Icons.tune,
                title: l10n.settingsRecordingQuality,
                trailing: SettingsChevron(value: widget.recordingQuality),
                onTap: widget.onRecordingQualityTap,
                isEnabled: false,
              ),
              SettingsRow(
                icon: Icons.mic_off_outlined,
                title: l10n.settingsVadTitle,
                subtitle: l10n.settingsVadSubtitle,
                trailing: SettingsToggle(
                  value: widget.vadEnabled,
                  onChanged: widget.onVadChanged,
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
                trailing: SettingsChevron(value: widget.defaultLanguage),
                onTap: widget.onDefaultLanguageTap,
                isEnabled: false,
              ),
              SettingsRow(
                icon: Icons.tag,
                title: l10n.settingsAutoTags,
                subtitle: l10n.settingsAutoTagsSubtitle,
                trailing: SettingsToggle(
                  value: widget.autoTags,
                  onChanged: widget.onAutoTagsChanged,
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
              SettingsRow(
                icon: Icons.dark_mode_outlined,
                title: l10n.settingsTheme,
                trailing: SettingsChevron(value: widget.theme),
                onTap: widget.onThemeTap,
                isEnabled: false,
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
                onTap: widget.onExportTap,
                isEnabled: false,
              ),
              SettingsRow(
                icon: Icons.delete_sweep_outlined,
                title: l10n.settingsClearCache,
                subtitle: l10n.settingsClearCacheSubtitle,
                trailing: const SettingsChevron(),
                onTap: widget.onClearCacheTap,
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

class _ModelsTab extends StatefulWidget {
  const _ModelsTab();

  @override
  State<_ModelsTab> createState() => _ModelsTabState();
}

class _ModelsTabState extends State<_ModelsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AsyncStateBody<ModelsCubit, ModelsState>(
      buildWhen: (_, _) => true,
      listener: _handleStateChanges,
      onSuccess: (context, state) {
        final models = state.models;

        if (models.isEmpty) return Center(child: Text(context.l10n.stateEmpty));

        final themeColors = context.themeColors;
        final activeModel = state.selectedModel;
        final otherModels = models.where((model) => !model.isSelected);

        return ListView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            if (activeModel != null) ...[
              Text(
                context.l10n.settingsActiveModel,
                style: AppTypography.overline.copyWith(
                  color: themeColors.textTertiary,
                ),
              ),
              AppSpacer.p8,
              _buildModelCard(context, state, activeModel),
              AppSpacer.p24,
            ],
            Text(
              context.l10n.settingsAvailableModels,
              style: AppTypography.overline.copyWith(
                color: themeColors.textTertiary,
              ),
            ),
            AppSpacer.p8,
            for (final model in otherModels)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.p12),
                child: _buildModelCard(context, state, model),
              ),
            AppSpacer.p40,
          ],
        );
      },
    );
  }

  void _handleStateChanges(
    BuildContext context,
    AsyncState<ModelsState> baseState,
  ) {
    if (baseState is! AsyncSuccess<ModelsState>) return;
    final state = baseState.data;

    // Показываем ошибки скачивания
    for (final entry in state.downloads.entries) {
      final progress = entry.value;
      if (progress.status == DownloadStatus.failed &&
          progress.errorMessage != null) {
        _showErrorDialog(context, progress.errorMessage!);
        break;
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => ErrorDialog(
        title: context.l10n.settingsDownloadError,
        message: message,
        icon: Icons.error_outline_rounded,
      ),
    );
  }

  Widget _buildModelCard(
    BuildContext context,
    ModelsState state,
    AsrModelEntity model,
  ) {
    final cubit = context.read<ModelsCubit>();
    final downloadProgress = state.getDownloadProgress(model.uuid);

    return ModelCard(
      model: model,
      downloadProgress: downloadProgress,
      onUse: model.isDownloaded && !model.isSelected
          ? () => cubit.selectModel(model)
          : null,
      onDownload: !model.isDownloaded && !state.isDownloading(model.uuid)
          ? () => _onDownloadModel(context, model)
          : null,
      onDelete: model.isDownloaded
          ? () => _onDeleteModel(context, model)
          : null,
      onPause: state.isDownloading(model.uuid)
          ? () => cubit.pauseDownload(model.uuid)
          : null,
      onResume: downloadProgress?.status == DownloadStatus.paused
          ? () => cubit.resumeDownload(model.uuid)
          : null,
      onCancel: state.isDownloading(model.uuid)
          ? () => cubit.cancelDownload(model.uuid)
          : null,
    );
  }

  Future<void> _onDownloadModel(
    BuildContext context,
    AsrModelEntity model,
  ) async {
    final cubit = context.read<ModelsCubit>();
    final failure = await cubit.downloadModel(model);

    if (failure != null && context.mounted) {
      await ErrorDialog.showFromFailure(context, failure);
    }
  }

  Future<void> _onDeleteModel(
    BuildContext context,
    AsrModelEntity model,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteModelTitle),
        content: Text(context.l10n.deleteModelMessage(model.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.dialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.dialogDelete),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<ModelsCubit>().deleteModel(model.uuid);
    }
  }
}
