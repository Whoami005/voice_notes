import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/downloader/download_manager.dart';
import 'package:voice_notes/core/packages/downloader/download_status.dart';
import 'package:voice_notes/core/theme/app_colors_extension.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

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
          Text(
            model.description,
            style: AppTypography.caption.copyWith(
              color: themeColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
    final isWhisper = engine.toLowerCase().contains('whisper');
    final color = isWhisper ? const Color(0xFF22C55E) : const Color(0xFF3B82F6);

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
        Text(
          model.languageLabel,
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
        'АКТИВНА',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildStatusText(themeColors)),
            if (progress.status == DownloadStatus.downloading ||
                progress.status == DownloadStatus.paused)
              _buildProgressPercent(themeColors),
          ],
        ),
        AppSpacer.p4,
        _buildProgressIndicator(themeColors),
        if (_showActionButtons) ...[
          AppSpacer.p12,
          _buildActionButtons(themeColors),
        ],
      ],
    );
  }

  Widget _buildStatusText(AppColorsExtension themeColors) {
    final (text, color) = switch (progress.status) {
      DownloadStatus.queued => ('В очереди...', themeColors.textSecondary),
      DownloadStatus.downloading => ('Загрузка...', themeColors.textSecondary),
      DownloadStatus.extracting => ('Распаковка...', themeColors.textSecondary),
      DownloadStatus.paused => ('Приостановлено', themeColors.warning),
      DownloadStatus.failed => (
        progress.errorMessage ?? 'Ошибка',
        themeColors.error,
      ),
      DownloadStatus.cancelled => ('Отменено', themeColors.textTertiary),
      _ => ('', themeColors.textSecondary),
    };

    return Text(
      text,
      style: AppTypography.caption.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressPercent(AppColorsExtension themeColors) {
    final percent = (progress.progress * 100).toInt();
    return Text(
      '$percent%',
      style: AppTypography.caption.copyWith(color: themeColors.textSecondary),
    );
  }

  Widget _buildProgressIndicator(AppColorsExtension themeColors) {
    final isIndeterminate =
        progress.status == DownloadStatus.queued ||
        progress.status == DownloadStatus.extracting;

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
      progress.status == DownloadStatus.downloading ||
      progress.status == DownloadStatus.paused ||
      progress.status == DownloadStatus.queued;

  Widget _buildActionButtons(AppColorsExtension themeColors) {
    final isPaused = progress.status == DownloadStatus.paused;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isPaused ? onResume : onPause,
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              size: AppSizes.iconMedium,
            ),
            label: Text(isPaused ? 'Продолжить' : 'Пауза'),
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
          label: const Text('Скачать'),
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
              ? OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeColors.textTertiary,
                    side: BorderSide(color: themeColors.borderPrimary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonRadius,
                      ),
                    ),
                  ),
                  child: const Text('Используется'),
                )
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
                  child: const Text('Использовать'),
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
