import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/transcription_failure_reason_l10n.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/core/theme/app_colors_extension.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/transcription/logic/queue_management_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/transcription/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class QueueManagementScreen extends StatelessWidget implements AppRouteWrapper {
  const QueueManagementScreen({super.key});

  static void go(BuildContext context) {
    context.push(AppRoutes.queue.root);
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          QueueManagementCubit(noteRepository: getIt<NoteRepository>()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: themeColors.bgPrimary,
        title: Text(context.l10n.queueScreenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.p16,
          horizontal: AppSizes.screenPadding,
        ),
        children: const [
          _StatusHeader(),
          AppSpacer.p20,
          _FailedSection(),
          AppSpacer.p24,
          _CancelledSection(),
          AppSpacer.p40,
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final bootstrap = context.select(
      (TranscriptionQueueCubit c) => c.state.snapshot.bootstrapState,
    );
    final paused = context.select(
      (TranscriptionQueueCubit c) => c.state.snapshot.paused,
    );
    final asrState = context.select(
      (AsrCubit c) => (status: c.state.status, hasModel: c.state.hasModel),
    );

    final (queueText, queueColor) = _queueStatusLabel(
      l10n: l10n,
      bootstrap: bootstrap,
      paused: paused,
      themeColors: themeColors,
    );
    final (asrText, asrColor) = _asrStatusLabel(
      l10n: l10n,
      status: asrState.status,
      hasModel: asrState.hasModel,
      themeColors: themeColors,
    );

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSizes.p8,
        children: [
          _StatusRow(
            icon: Icons.queue_outlined,
            label: queueText,
            color: queueColor,
          ),
          _StatusRow(icon: Icons.memory, label: asrText, color: asrColor),
        ],
      ),
    );
  }

  (String, Color) _queueStatusLabel({
    required AppLocalizations l10n,
    required QueueBootstrapState bootstrap,
    required bool paused,
    required AppColorsExtension themeColors,
  }) {
    return switch (bootstrap) {
      QueueBootstrapError() => (l10n.queueBootstrapError, themeColors.error),
      QueueBootstrapLoading() ||
      QueueBootstrapNotStarted() => (l10n.queueStatusLoading, themeColors.info),
      QueueBootstrapReady() =>
        paused
            ? (l10n.queueStatusPaused, themeColors.warning)
            : (l10n.queueStatusActive, themeColors.success),
    };
  }

  (String, Color) _asrStatusLabel({
    required AppLocalizations l10n,
    required Status status,
    required bool hasModel,
    required AppColorsExtension themeColors,
  }) {
    if (status == Status.success && hasModel) {
      return (l10n.queueAsrReady, themeColors.success);
    }
    return (l10n.queueAsrNotReady, themeColors.warning);
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSizes.p8,
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: color),
        Flexible(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _FailedSection extends StatelessWidget {
  const _FailedSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failed = context.select((QueueManagementCubit c) => c.state.failed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.p12,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.queueFailedSection(failed.length),
                style: AppTypography.h3.copyWith(
                  color: context.themeColors.textPrimary,
                ),
              ),
            ),
            if (failed.isNotEmpty) ...[
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: AppSizes.iconSmall),
                label: Text(l10n.queueRetryAll),
                onPressed: context.read<TranscriptionQueueCubit>().retryAll,
              ),
              TextButton.icon(
                icon: const Icon(Icons.close, size: AppSizes.iconSmall),
                label: Text(l10n.queueClearAll),
                onPressed: context
                    .read<TranscriptionQueueCubit>()
                    .clearFailedAll,
              ),
            ],
          ],
        ),
        if (failed.isEmpty)
          _EmptyHint(text: l10n.queueEmptyFailed)
        else
          for (final note in failed)
            _NoteTile(note: note, kind: _NoteKind.failed),
      ],
    );
  }
}

class _CancelledSection extends StatelessWidget {
  const _CancelledSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cancelled = context.select(
      (QueueManagementCubit c) => c.state.cancelled,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.p12,
      children: [
        Text(
          l10n.queueCancelledSection(cancelled.length),
          style: AppTypography.h3.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        if (cancelled.isEmpty)
          _EmptyHint(text: l10n.queueEmptyCancelled)
        else
          for (final note in cancelled)
            _NoteTile(note: note, kind: _NoteKind.cancelled),
      ],
    );
  }
}

enum _NoteKind { failed, cancelled }

class _NoteTile extends StatelessWidget {
  final NoteEntity note;
  final _NoteKind kind;

  const _NoteTile({required this.note, required this.kind});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final subtitle = kind == _NoteKind.failed
        ? note.failureReason?.title(l10n) ?? l10n.noteFailureUnknown
        : _formatTimestamp(note.updatedAt);

    final title = note.text.trim().isEmpty
        ? l10n.queueItemUntitled
        : _truncate(note.text, 60);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: themeColors.textPrimary,
                  ),
                ),
                AppSpacer.p4,
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: kind == _NoteKind.failed
                        ? themeColors.error
                        : themeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.noteActionRetry,
            onPressed: () =>
                context.read<TranscriptionQueueCubit>().retry(note.uuid),
          ),
          if (kind == _NoteKind.failed)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context
                  .read<TranscriptionQueueCubit>()
                  .dismissFailed(note.uuid),
            ),
        ],
      ),
    );
  }

  String _truncate(String text, int max) {
    final trimmed = text.trim();
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max).trimRight()}…';
  }

  String _formatTimestamp(DateTime ts) =>
      DateFormat('dd.MM.yyyy HH:mm').format(ts);
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: themeColors.textTertiary),
      ),
    );
  }
}
