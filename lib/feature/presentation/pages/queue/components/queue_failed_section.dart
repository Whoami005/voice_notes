import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/transcription_failure_reason_l10n.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/queue_management_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/kanban_note_tile.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/queue_group.dart';

class QueueFailedSection extends StatelessWidget {
  const QueueFailedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final cubit = context.read<TranscriptionQueueCubit>();
    final failed = context.select((QueueManagementCubit c) => c.state.failed);

    return QueueGroup(
      accentColor: themeColors.error,
      title: l10n.queueFailedSection,
      count: failed.length,
      countColor: themeColors.error,
      actions: failed.isNotEmpty
          ? [
              QueueHeaderAction(
                icon: Icons.refresh,
                label: l10n.queueRetryAll,
                color: themeColors.info,
                onPressed: cubit.retryAll,
              ),
              QueueHeaderAction(
                icon: Icons.close,
                label: l10n.queueClearAll,
                color: themeColors.textSecondary,
                onPressed: cubit.clearFailedAll,
              ),
            ]
          : [],
      children: [
        if (failed.isEmpty)
          QueueGroupEmpty(text: l10n.queueEmptyFailed)
        else
          for (final note in failed)
            KanbanNoteTile(
              note: note,
              statusColor: themeColors.error,
              footerHint:
                  note.failureReason?.title(l10n) ?? l10n.noteFailureUnknown,
              footerHintColor: themeColors.error,
              footerHintIcon: Icons.error_outline,
              actions: [
                TileAction(
                  icon: Icons.refresh,
                  color: themeColors.info,
                  onPressed: () => cubit.retry(note.uuid),
                ),
                TileAction(
                  icon: Icons.close,
                  color: themeColors.textSecondary,
                  onPressed: () => cubit.dismissFailed(note.uuid),
                ),
              ],
            ),
      ],
    );
  }
}
