import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

class ModelCard extends StatelessWidget {
  final AsrModelEntity model;
  final VoidCallback? onUse;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const ModelCard({
    required this.model,
    super.key,
    this.onUse,
    this.onDownload,
    this.onDelete,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ModelIcon(engine: model.engine),
              AppSpacer.p12,
              Expanded(
                child: _ModelInfo(model: model),
              ),
              if (model.isSelected) const _ActiveBadge(),
            ],
          ),
          AppSpacer.p12,
          Text(
            model.description,
            style: AppTypography.caption.copyWith(
              color: themeColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (model.downloadProgress != null) ...[
            AppSpacer.p12,
            _DownloadProgress(progress: model.downloadProgress!),
          ],
          AppSpacer.p12,
          _ActionButtons(
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
          style: AppTypography.h3.copyWith(
            color: themeColors.textPrimary,
          ),
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
          model.languages,
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

class _DownloadProgress extends StatelessWidget {
  final double progress;

  const _DownloadProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final percent = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Загрузка...',
              style: AppTypography.caption.copyWith(
                color: themeColors.textSecondary,
              ),
            ),
            Text(
              '$percent%',
              style: AppTypography.caption.copyWith(
                color: themeColors.textSecondary,
              ),
            ),
          ],
        ),
        AppSpacer.p4,
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.p4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: themeColors.bgTertiary,
            valueColor: AlwaysStoppedAnimation(themeColors.accentPrimary),
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
    final isDownloading = model.downloadProgress != null;

    if (isDownloading) {
      return const SizedBox.shrink();
    }

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
