import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/queue_management_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/queue/utils/queue_confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/pages/queue/utils/queue_formatters.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/kanban_note_tile.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/queue_group.dart';

class QueueQueuedSection extends StatelessWidget {
  const QueueQueuedSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final queued = context.select((QueueManagementCubit c) => c.state.queued);
    final cancelRequested = context.select(
      (QueueManagementCubit c) => c.state.cancelRequested,
    );
    final cubit = context.read<TranscriptionQueueCubit>();

    return QueueGroup(
      accentColor: themeColors.info.withValues(alpha: 0.7),
      title: l10n.queueQueuedSection,
      count: queued.length,
      actions: queued.isNotEmpty
          ? [
              QueueHeaderAction(
                icon: Icons.close,
                label: l10n.queueCancelAll,
                color: themeColors.error,
                onPressed: () async {
                  final confirmed = await showQueueDestructiveConfirm(
                    context,
                    title: l10n.queueCancelAllQueuedConfirmTitle,
                    body: l10n.queueCancelAllQueuedConfirmBody(queued.length),
                    confirmLabel: l10n.queueConfirmCancel,
                  );

                  if (!confirmed || !context.mounted) return;

                  await cubit.cancelAll();
                },
              ),
            ]
          : [],
      children: [
        if (queued.isEmpty)
          QueueGroupEmpty(text: l10n.queueEmptyQueued)
        else
          for (final note in queued)
            KanbanNoteTile(
              note: note,
              statusColor: themeColors.info,
              footerHint: cancelRequested.contains(note.uuid)
                  ? l10n.queueItemCancelling
                  : formatDuration(note.origin.sourceDurationOrZero),
              footerHintColor: cancelRequested.contains(note.uuid)
                  ? themeColors.warning
                  : themeColors.textSecondary,
              footerHintIcon: cancelRequested.contains(note.uuid)
                  ? null
                  : Icons.schedule_outlined,
              actions: [
                TileAction(
                  icon: Icons.close,
                  color: themeColors.textSecondary,
                  onPressed: cancelRequested.contains(note.uuid)
                      ? null
                      : () => cubit.cancel(note.uuid),
                ),
              ],
            ),
      ],
    );
  }
}
