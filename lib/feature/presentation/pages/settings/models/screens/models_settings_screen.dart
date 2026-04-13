import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/state/async/async_state_widgets.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/logic/models_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/widgets/model_card.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';

class ModelsSettingsScreen extends StatefulWidget {
  const ModelsSettingsScreen({super.key});

  static void go(BuildContext context) {
    context.go(AppRoutes.settings.models);
  }

  @override
  State<ModelsSettingsScreen> createState() => _ModelsSettingsScreenState();
}

class _ModelsSettingsScreenState extends State<ModelsSettingsScreen> {
  void _handleStateChanges(
    BuildContext context,
    AsyncState<ModelsState> baseState,
  ) {
    if (baseState is! AsyncSuccess<ModelsState>) return;
    final state = baseState.data;

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
      await context.read<ModelsCubit>().deleteModel(model.uuid.value);
    }
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

  @override
  Widget build(BuildContext context) {
    return AsyncStateBody<ModelsCubit, ModelsState>(
      buildAlways: true,
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

  Widget _buildModelCard(
    BuildContext context,
    ModelsState state,
    AsrModelEntity model,
  ) {
    final cubit = context.read<ModelsCubit>();
    final modelId = model.uuid.value;
    final downloadProgress = state.getDownloadProgress(modelId);

    return ModelCard(
      model: model,
      downloadProgress: downloadProgress,
      onUse: model.isDownloaded && !model.isSelected
          ? () => cubit.selectModel(model)
          : null,
      onDownload: !model.isDownloaded && !state.isDownloading(modelId)
          ? () => _onDownloadModel(context, model)
          : null,
      onDelete: model.isDownloaded
          ? () => _onDeleteModel(context, model)
          : null,
      onPause: state.isDownloading(modelId)
          ? () => cubit.pauseDownload(modelId)
          : null,
      onResume: downloadProgress?.status == DownloadStatus.paused
          ? () => cubit.resumeDownload(modelId)
          : null,
      onCancel: state.isDownloading(modelId)
          ? () => cubit.cancelDownload(modelId)
          : null,
    );
  }
}
