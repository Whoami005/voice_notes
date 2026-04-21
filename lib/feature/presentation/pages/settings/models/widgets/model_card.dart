import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/download_status_l10n.dart';
import 'package:voice_notes/core/l10n/localized_models.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/packages/downloader/download_manager.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/core/theme/app_colors_extension.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class ModelCard extends StatelessWidget {
  final AsrModelEntity model;
  final ModelDownloadProgress? downloadProgress;
  final VoidCallback? onUse;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const ModelCard({
    required this.model,
    super.key,
    this.downloadProgress,
    this.onUse,
    this.onDownload,
    this.onDelete,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final description = LocalizedModels.description(model.uuid, context.l10n);

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(
          color: model.isSelected
              ? themeColors.accentPrimary
              : themeColors.borderPrimary,
          width: model.isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        spacing: AppSizes.p12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ModelIcon(engine: model.engine),
              AppSpacer.p12,
              Expanded(child: _ModelInfo(model: model)),
              if (model.isSelected) const _ActiveBadge(),
            ],
          ),
          if (description != null)
            Text(
              description,
              style: AppTypography.caption.copyWith(
                color: themeColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (model.supportsStreaming) _ModelCapabilitiesSection(model: model),
          _ModelRecommendationSection(model: model),
          downloadProgress != null
              ? _DownloadProgressWidget(
                  progress: downloadProgress!,
                  onPause: onPause,
                  onResume: onResume,
                  onCancel: onCancel,
                )
              : _ActionButtons(
                  model: model,
                  onUse: onUse,
                  onDownload: onDownload,
                  onDelete: onDelete,
                ),
        ],
      ),
    );
  }
}

class _ModelIcon extends StatelessWidget {
  final String engine;

  const _ModelIcon({required this.engine});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final isWhisper = engine.toLowerCase().contains('whisper');
    final color = isWhisper ? themeColors.success : themeColors.info;

    return Container(
      width: AppSizes.avatarMedium,
      height: AppSizes.avatarMedium,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Icon(
        isWhisper ? Icons.graphic_eq : Icons.memory,
        color: color,
        size: AppSizes.iconLarge,
      ),
    );
  }
}

class _ModelInfo extends StatelessWidget {
  final AsrModelEntity model;

  const _ModelInfo({required this.model});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final languageLabel = LocalizedModels.languageLabel(
      model.uuid,
      context.l10n,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          model.name,
          style: AppTypography.h3.copyWith(color: themeColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        AppSpacer.p2,
        Text(
          '${model.engine} • ${model.size}',
          style: AppTypography.caption.copyWith(
            color: themeColors.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        AppSpacer.p2,
        if (languageLabel != null)
          Text(
            languageLabel,
            style: AppTypography.caption.copyWith(
              color: themeColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

/// Секция «Возможности» для streaming-моделей: три капабилити-чипа.
///
/// Не показывается для non-streaming моделей — для них есть только секция
/// «Рекомендации» с подсказкой про ≤5 минут.
class _ModelCapabilitiesSection extends StatelessWidget {
  final AsrModelEntity model;

  const _ModelCapabilitiesSection({required this.model});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSizes.p8,
      children: [
        Text(
          l10n.modelCapabilitiesTitle,
          style: AppTypography.micro.copyWith(
            color: themeColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p6,
          children: [
            _CapabilityChip(
              key: const Key('model-card-capability-realtime'),
              icon: Icons.speed,
              label: l10n.modelCapabilityRealTimeProgress,
            ),
            _CapabilityChip(
              key: const Key('model-card-capability-cancelable'),
              icon: Icons.cancel_outlined,
              label: l10n.modelCapabilityCancelable,
            ),
            _CapabilityChip(
              key: const Key('model-card-capability-partial-text'),
              icon: Icons.text_snippet_outlined,
              label: l10n.modelCapabilityLivePartialText,
            ),
          ],
        ),
      ],
    );
  }
}

/// Секция «Рекомендации» — подсказка по выбору длины записи.
class _ModelRecommendationSection extends StatelessWidget {
  final AsrModelEntity model;

  const _ModelRecommendationSection({required this.model});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;
    final text = model.supportsStreaming
        ? l10n.modelTipStreamingForLongRecords
        : l10n.modelTipOfflineShortRecords;

    return Row(
      key: const Key('model-card-recommendation'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: AppSizes.p16,
          color: themeColors.textTertiary,
        ),
        AppSpacer.p8,
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Компактный чип с иконкой и лейблом для capabilities-секции.
/// Приватный: единственный потребитель — [_ModelCapabilitiesSection].
class _CapabilityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CapabilityChip({required this.icon, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: themeColors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSizes.p6,
        children: [
          Icon(icon, size: AppSizes.p14, color: themeColors.accentPrimary),
          Text(
            label,
            style: AppTypography.micro.copyWith(
              color: themeColors.accentPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p2,
      ),
      decoration: BoxDecoration(
        color: themeColors.accentPrimary,
        borderRadius: BorderRadius.circular(AppSizes.p10),
      ),
      child: Text(
        context.l10n.modelCardActive,
        style: AppTypography.micro.copyWith(
          color: themeColors.textInverse,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DownloadProgressWidget extends StatelessWidget {
  final ModelDownloadProgress progress;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const _DownloadProgressWidget({
    required this.progress,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildStatusText(themeColors, l10n)),
            if (progress.status.isDownloading || progress.status.isPaused)
              _buildProgressPercent(themeColors),
          ],
        ),
        AppSpacer.p4,
        _buildProgressIndicator(themeColors),
        if (_showActionButtons) ...[
          AppSpacer.p12,
          _buildActionButtons(themeColors, l10n),
        ],
      ],
    );
  }

  Widget _buildStatusText(
    AppColorsExtension themeColors,
    AppLocalizations l10n,
  ) {
    final text = progress.status.isFailed
        ? progress.errorMessage ?? l10n.modelStatusError
        : progress.status.statusTitle(l10n);

    final color = switch (progress.status) {
      DownloadStatus.paused => themeColors.warning,
      DownloadStatus.failed => themeColors.error,
      DownloadStatus.cancelled => themeColors.textTertiary,
      _ => themeColors.textSecondary,
    };

    return Text(
      text,
      style: AppTypography.caption.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressPercent(AppColorsExtension themeColors) {
    final percent = math.max(0, (progress.progress * 100).toInt());

    return Text(
      '$percent%',
      style: AppTypography.caption.copyWith(color: themeColors.textSecondary),
    );
  }

  Widget _buildProgressIndicator(AppColorsExtension themeColors) {
    final isIndeterminate =
        progress.status.isQueued || progress.status.isExtracting;

    final color = switch (progress.status) {
      DownloadStatus.paused => themeColors.warning,
      DownloadStatus.failed => themeColors.error,
      DownloadStatus.cancelled => themeColors.textTertiary,
      _ => themeColors.accentPrimary,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.p4),
      child: isIndeterminate
          ? LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: themeColors.bgTertiary,
              valueColor: AlwaysStoppedAnimation(color),
            )
          : LinearProgressIndicator(
              value: progress.progress,
              minHeight: 4,
              backgroundColor: themeColors.bgTertiary,
              valueColor: AlwaysStoppedAnimation(color),
            ),
    );
  }

  bool get _showActionButtons =>
      progress.status.isDownloading ||
      progress.status.isPaused ||
      progress.status.isQueued;

  Widget _buildActionButtons(
    AppColorsExtension themeColors,
    AppLocalizations l10n,
  ) {
    final isPaused = progress.status.isPaused;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPaused ? onResume : onPause,
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              size: AppSizes.iconMedium,
            ),
            label: Text(
              isPaused ? l10n.modelActionResume : l10n.modelActionPause,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: themeColors.textSecondary,
              side: BorderSide(color: themeColors.borderPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
              ),
            ),
          ),
        ),
        AppSpacer.p8,
        IconButton(
          onPressed: onCancel,
          icon: Icon(
            Icons.close,
            color: themeColors.error,
            size: AppSizes.iconLarge,
          ),
          style: IconButton.styleFrom(
            backgroundColor: themeColors.error.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AsrModelEntity model;
  final VoidCallback? onUse;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const _ActionButtons({
    required this.model,
    this.onUse,
    this.onDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    if (!model.isDownloaded) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download, size: AppSizes.iconMedium),
          label: Text(context.l10n.modelActionDownload),
          style: OutlinedButton.styleFrom(
            foregroundColor: themeColors.accentPrimary,
            side: BorderSide(color: themeColors.accentPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: model.isSelected
              ? _SelectedModelButton(themeColors: themeColors)
              : ElevatedButton(
                  onPressed: onUse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColors.accentPrimary,
                    foregroundColor: themeColors.textInverse,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonRadius,
                      ),
                    ),
                  ),
                  child: Text(context.l10n.modelActionUse),
                ),
        ),
        AppSpacer.p8,
        IconButton(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            color: themeColors.error,
            size: AppSizes.iconLarge,
          ),
          style: IconButton.styleFrom(
            backgroundColor: themeColors.error.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            ),
          ),
        ),
      ],
    );
  }
}

/// Кнопка для выбранной модели — реагирует на состояние AsrCubit.
///
/// - loading → "Инициализация..." с спиннером
/// - success → "Используется" (неактивна)
/// - error → "Переинициализировать" (активна)
class _SelectedModelButton extends StatelessWidget {
  final AppColorsExtension themeColors;

  const _SelectedModelButton({required this.themeColors});

  @override
  Widget build(BuildContext context) {
    final asrStatus = context.select((AsrCubit c) => c.state.status);
    final l10n = context.l10n;

    return switch (asrStatus) {
      Status.loading => OutlinedButton.icon(
        onPressed: null,
        icon: SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: themeColors.textTertiary,
          ),
        ),
        label: Text(l10n.asrInitializing, textAlign: TextAlign.center),
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.textTertiary,
          side: BorderSide(color: themeColors.borderPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
      Status.error => OutlinedButton.icon(
        onPressed: context.read<AsrCubit>().retry,
        icon: const Icon(Icons.refresh, size: AppSizes.iconMedium),
        label: Text(l10n.asrReinitialize),
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.error,
          side: BorderSide(color: themeColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
      _ => OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.textTertiary,
          side: BorderSide(color: themeColors.borderPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
        child: Text(l10n.modelActionInUse),
      ),
    };
  }
}
