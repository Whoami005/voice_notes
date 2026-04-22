import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/enums/queue_runtime_reason.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/queue_management_cubit.dart';

class QueueWarningBanner extends StatelessWidget {
  const QueueWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final bootstrap = context.select(
      (QueueManagementCubit c) => c.state.bootstrapState,
    );
    final runtimeReason = context.select(
      (QueueManagementCubit c) => c.state.runtimeReason,
    );

    final (text, color) = switch ((bootstrap, runtimeReason)) {
      (QueueBootstrapError(), _) => (
        l10n.queueBannerBootstrapError,
        themeColors.error,
      ),
      (_, QueueRuntimeReason.interruptedPreviousRun) => (
        l10n.queueBannerInterruptedPreviousRun,
        themeColors.warning,
      ),
      (_, QueueRuntimeReason.awaitingModel) => (
        l10n.queueBannerAwaitingModel,
        themeColors.warning,
      ),
      (_, QueueRuntimeReason.breakerTripped) => (
        l10n.queueBannerBreakerTripped,
        themeColors.warning,
      ),
      _ => (null, themeColors.warning),
    };

    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p10,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(AppSizes.p12),
        ),
        child: Row(
          spacing: AppSizes.p8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: AppSizes.iconSmall,
              color: color,
            ),
            Expanded(
              child: Text(
                text,
                style: AppTypography.caption.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
