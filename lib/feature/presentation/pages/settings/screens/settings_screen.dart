import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/core/state/base_state.dart';
import 'package:voice_notes/core/state/base_state_builder.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/logic/models_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/widgets/model_card.dart';
import 'package:voice_notes/feature/presentation/pages/settings/widgets/settings_row.dart';
import 'package:voice_notes/feature/presentation/pages/settings/widgets/settings_section.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';

class SettingsScreen extends StatefulWidget implements AppRouteWrapper {
  const SettingsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ModelsCubit(repository: getIt<ModelRepository>())..init(),
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

  void _onAppLanguageTap() {
    // TODO: Show language dialog
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
  State<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<_GeneralTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                  value: widget.autoSave,
                  onChanged: widget.onAutoSaveChanged,
                ),
              ),
              SettingsRow(
                icon: Icons.tune,
                title: 'Качество записи',
                trailing: SettingsChevron(value: widget.recordingQuality),
                onTap: widget.onRecordingQualityTap,
              ),
              SettingsRow(
                icon: Icons.mic_off_outlined,
                title: 'VAD',
                subtitle: 'Авто-стоп при тишине',
                trailing: SettingsToggle(
                  value: widget.vadEnabled,
                  onChanged: widget.onVadChanged,
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
                trailing: SettingsChevron(value: widget.defaultLanguage),
                onTap: widget.onDefaultLanguageTap,
              ),
              SettingsRow(
                icon: Icons.tag,
                title: 'Авто-теги',
                subtitle: 'Автоматически добавлять теги',
                trailing: SettingsToggle(
                  value: widget.autoTags,
                  onChanged: widget.onAutoTagsChanged,
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
                trailing: SettingsChevron(value: widget.theme),
                onTap: widget.onThemeTap,
              ),
              SettingsRow(
                icon: Icons.translate,
                title: 'Язык приложения',
                trailing: SettingsChevron(value: widget.appLanguage),
                onTap: widget.onAppLanguageTap,
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
                onTap: widget.onExportTap,
              ),
              SettingsRow(
                icon: Icons.delete_sweep_outlined,
                title: 'Очистка кэша',
                subtitle: 'Освободить место на устройстве',
                trailing: const SettingsChevron(),
                onTap: widget.onClearCacheTap,
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

    return BaseStateBuilder<ModelsCubit, ModelsState>(
      buildWhen: (_, _) => true,
      listener: _handleStateChanges,
      onSuccess: (context, state) {
        final models = state.models;

        if (models.isEmpty) return const Center(child: Text('Пусто'));

        final themeColors = context.themeColors;
        final activeModel = state.selectedModel;
        final otherModels = models.where((model) => !model.isSelected);

        return ListView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            if (activeModel != null) ...[
              Text(
                'АКТИВНАЯ МОДЕЛЬ',
                style: AppTypography.overline.copyWith(
                  color: themeColors.textTertiary,
                ),
              ),
              AppSpacer.p8,
              _buildModelCard(context, state, activeModel),
              AppSpacer.p24,
            ],
            Text(
              'ДОСТУПНЫЕ МОДЕЛИ',
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
    BaseState<ModelsState> baseState,
  ) {
    if (baseState is! SuccessState<ModelsState>) return;
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
        title: 'Ошибка загрузки',
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
    final downloadProgress = state.getDownloadProgress(model.id);

    return ModelCard(
      model: model,
      downloadProgress: downloadProgress,
      onUse: model.isDownloaded && !model.isSelected
          ? () => cubit.selectModel(model.id)
          : null,
      onDownload: !model.isDownloaded && !state.isDownloading(model.id)
          ? () => _onDownloadModel(context, model)
          : null,
      onDelete: model.isDownloaded
          ? () => _onDeleteModel(context, model)
          : null,
      onPause: state.isDownloading(model.id)
          ? () => cubit.pauseDownload(model.id)
          : null,
      onResume: downloadProgress?.status == DownloadStatus.paused
          ? () => cubit.resumeDownload(model.id)
          : null,
      onCancel: state.isDownloading(model.id)
          ? () => cubit.cancelDownload(model.id)
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
        title: const Text('Удалить модель?'),
        content: Text(
          'Модель "${model.name}" будет удалена с устройства. '
          'Вы сможете скачать её снова.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<ModelsCubit>().deleteModel(model.id);
    }
  }
}
