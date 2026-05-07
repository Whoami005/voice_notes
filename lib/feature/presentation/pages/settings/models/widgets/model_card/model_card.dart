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
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

part 'active_badge.dart';
part 'capability_chip.dart';
part 'download_action_buttons.dart';
part 'download_progress_indicator.dart';
part 'download_progress_panel.dart';
part 'download_progress_percent.dart';
part 'download_status_text.dart';
part 'model_action_buttons.dart';
part 'model_capabilities_section.dart';
part 'model_icon.dart';
part 'model_info.dart';
part 'model_recommendation_section.dart';
part 'selected_model_button.dart';

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
    final progress = downloadProgress;

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: model.isSelected
            ? Border.all(
                color: themeColors.accentPrimary,
                width: AppSizes.strokeThin,
              )
            : Border.all(color: themeColors.borderPrimary),
      ),
      child: Column(
        spacing: AppSizes.p12,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: AppSizes.p12,
            children: [
              _ModelIcon(engine: model.engine),
              Expanded(child: _ModelInfo(model: model)),
              if (model.isSelected) const _ActiveBadge(),
            ],
          ),
          if (description != null)
            Text(
              description,
              maxLines: 2,
              style: AppTypography.caption.copyWith(
                color: themeColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (model.supportsStreaming) _ModelCapabilitiesSection(model: model),
          _ModelRecommendationSection(model: model),
          if (progress != null)
            _DownloadProgressPanel(
              progress: progress,
              onPause: onPause,
              onResume: onResume,
              onCancel: onCancel,
            )
          else
            _ModelActionButtons(
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
