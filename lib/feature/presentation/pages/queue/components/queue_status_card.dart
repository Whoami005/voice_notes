import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/theme/app_colors_extension.dart';
import 'package:voice_notes/feature/domain/enums/queue_runtime_reason.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/queue_management_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/ok_chip.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/queue_counters.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/queue_system_row.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/screens/models_settings_screen.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class QueueStatusCard extends StatelessWidget {
  const QueueStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QueueSystemStatusRow(),
          Divider(height: AppSizes.p16),
          _ModelStatusRow(),
          AppSpacer.p12,
          _CountersBlock(),
        ],
      ),
    );
  }
}

class _QueueSystemStatusRow extends StatelessWidget {
  const _QueueSystemStatusRow();

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

    final (subText, tone) = _queueStatusLabel(
      l10n: l10n,
      bootstrap: bootstrap,
      runtimeReason: runtimeReason,
      themeColors: themeColors,
    );

    final trailing = switch ((bootstrap, runtimeReason)) {
      (QueueBootstrapError(), _) => TextButton.icon(
        icon: const Icon(Icons.refresh, size: AppSizes.iconSmall),
        label: Text(l10n.queueSystemActionRetry),
        onPressed: context.read<TranscriptionQueueCubit>().retryBootstrap,
      ),
      (_, QueueRuntimeReason.breakerTripped) => TextButton.icon(
        icon: const Icon(Icons.refresh, size: AppSizes.iconSmall),
        label: Text(l10n.queueSystemActionRetry),
        onPressed: context.read<TranscriptionQueueCubit>().retryAll,
      ),
      _ => const OkChip(),
    };

    return QueueSystemRow(
      icon: Icons.queue_outlined,
      iconTone: tone,
      title: l10n.queueSystemQueueTitle,
      subtitle: subText,
      subtitleColor: tone,
      trailing: trailing,
    );
  }

  (String, Color) _queueStatusLabel({
    required AppLocalizations l10n,
    required QueueBootstrapState bootstrap,
    required QueueRuntimeReason runtimeReason,
    required AppColorsExtension themeColors,
  }) {
    return switch (bootstrap) {
      QueueBootstrapError() => (l10n.queueBootstrapError, themeColors.error),
      QueueBootstrapLoading() ||
      QueueBootstrapNotStarted() => (l10n.queueStatusLoading, themeColors.info),
      QueueBootstrapReady() => switch (runtimeReason) {
        QueueRuntimeReason.breakerTripped => (
          l10n.queueStatusPaused,
          themeColors.warning,
        ),
        QueueRuntimeReason.awaitingModel => (
          l10n.queueStatusAwaitingModel,
          themeColors.warning,
        ),
        QueueRuntimeReason.none => (
          l10n.queueStatusActive,
          themeColors.success,
        ),
      },
    };
  }
}

class _ModelStatusRow extends StatelessWidget {
  const _ModelStatusRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final asrState = context.select(
      (AsrCubit c) => (status: c.state.status, hasModel: c.state.hasModel),
    );

    final isReady = asrState.status.isSuccess && asrState.hasModel;
    final subText = isReady ? l10n.queueAsrReady : l10n.queueAsrNotReady;
    final tone = isReady ? themeColors.success : themeColors.warning;

    final trailing = isReady
        ? const OkChip()
        : TextButton.icon(
            icon: const Icon(Icons.arrow_forward, size: AppSizes.iconSmall),
            label: Text(l10n.queueSystemActionModelSettings),
            onPressed: () => ModelsSettingsScreen.go(context),
          );

    return QueueSystemRow(
      icon: Icons.memory,
      iconTone: tone,
      title: l10n.queueSystemModelTitle,
      subtitle: subText,
      subtitleColor: tone,
      trailing: trailing,
    );
  }
}

class _CountersBlock extends StatelessWidget {
  const _CountersBlock();

  @override
  Widget build(BuildContext context) {
    final counters = context.select(
      (QueueManagementCubit c) => (
        queued: c.state.queued.length,
        processing: c.state.hasProcessing ? 1 : 0,
        failed: c.state.failed.length,
        cancelled: c.state.cancelled.length,
      ),
    );

    return QueueCountersGrid(
      processing: counters.processing,
      queued: counters.queued,
      failed: counters.failed,
      cancelled: counters.cancelled,
    );
  }
}
