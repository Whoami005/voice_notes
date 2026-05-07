import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/logic/models_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/widgets/model_card/model_card.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';

class ModelsSettingsModelCard extends StatelessWidget {
  final ModelsState state;
  final AsrModelEntity model;

  const ModelsSettingsModelCard({
    required this.state,
    required this.model,
    super.key,
  });

  Future<void> _onDeleteModel(BuildContext context) async {
    final themeColors = context.themeColors;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: context.l10n.deleteModelTitle,
      message: context.l10n.deleteModelMessage(model.name),
      confirmText: context.l10n.dialogDelete,
      confirmColor: themeColors.error,
      icon: Icons.delete_outline_rounded,
    );

    if ((confirmed ?? false) && context.mounted) {
      await context.read<ModelsCubit>().deleteModel(model.uuid.value);
    }
  }

  Future<void> _onDownloadModel(BuildContext context) async {
    final cubit = context.read<ModelsCubit>();
    final failure = await cubit.downloadModel(model);

    if (failure != null && context.mounted) {
      await ErrorDialog.showFromFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ModelsCubit>();
    final modelId = model.uuid.value;
    final downloadProgress = state.getDownloadProgress(modelId);
    final isDownloading = state.isDownloading(modelId);

    return ModelCard(
      model: model,
      downloadProgress: downloadProgress,
      onUse: model.isDownloaded && !model.isSelected
          ? () => cubit.selectModel(model)
          : null,
      onDownload: !model.isDownloaded && !isDownloading
          ? () => _onDownloadModel(context)
          : null,
      onDelete: model.isDownloaded ? () => _onDeleteModel(context) : null,
      onPause: isDownloading ? () => cubit.pauseDownload(modelId) : null,
      onResume: downloadProgress?.status == DownloadStatus.paused
          ? () => cubit.resumeDownload(modelId)
          : null,
      onCancel: isDownloading ? () => cubit.cancelDownload(modelId) : null,
    );
  }
}
