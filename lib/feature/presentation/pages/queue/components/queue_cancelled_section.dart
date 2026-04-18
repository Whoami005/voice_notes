import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/queue_management_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/queue/utils/queue_confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/pages/queue/utils/queue_formatters.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/kanban_note_tile.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/queue_group.dart';

class QueueCancelledSection extends StatelessWidget {
  const QueueCancelledSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final queueCubit = context.read<QueueManagementCubit>();
    final cancelled = context.select(
      (QueueManagementCubit c) => c.state.cancelled,
    );

    return QueueGroup(
      accentColor: themeColors.textTertiary,
      title: l10n.queueCancelledSection,
      count: cancelled.length,
      actions: cancelled.isNotEmpty
          ? [
              QueueHeaderAction(
                icon: Icons.refresh,
                label: l10n.queueRetryAllCancelled,
                color: themeColors.info,
                onPressed: queueCubit.retryAllCancelled,
              ),
              QueueHeaderAction(
                icon: Icons.delete_outline,
                label: l10n.queueDeleteAllCancelled,
                color: themeColors.error,
                onPressed: () async {
                  final confirmed = await showQueueDestructiveConfirm(
                    context,
                    title: l10n.queueDeleteAllCancelledConfirmTitle,
                    body: l10n.queueDeleteAllCancelledConfirmBody(
                      cancelled.length,
                    ),
                    confirmLabel: l10n.queueConfirmDelete,
                  );

                  if (!confirmed || !context.mounted) return;

                  await queueCubit.deleteAllCancelled();
                },
              ),
            ]
          : [],
      children: [
        if (cancelled.isEmpty)
          QueueGroupEmpty(text: l10n.queueEmptyCancelled)
        else
          for (final note in cancelled)
            KanbanNoteTile(
              note: note,
              statusColor: themeColors.textTertiary,
              footerHint: formatTimestamp(note.updatedAt),
              footerHintColor: themeColors.textSecondary,
              footerHintIcon: Icons.schedule_outlined,
              actions: [
                TileAction(
                  icon: Icons.refresh,
                  color: themeColors.info,
                  onPressed: () =>
                      context.read<TranscriptionQueueCubit>().retry(note.uuid),
                ),
                TileAction(
                  icon: Icons.delete_outline,
                  color: themeColors.error,
                  onPressed: () async {
                    final confirmed = await showQueueDestructiveConfirm(
                      context,
                      title: l10n.queueDeleteCancelledConfirmTitle,
                      body: l10n.queueDeleteCancelledConfirmBody,
                      confirmLabel: l10n.queueConfirmDelete,
                    );

                    if (!confirmed || !context.mounted) return;

                    await queueCubit.deleteCancelled(note.uuid);
                  },
                ),
              ],
            ),
      ],
    );
  }
}
