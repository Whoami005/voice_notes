import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/queue_management_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/kanban_note_tile.dart';
import 'package:voice_notes/feature/presentation/pages/queue/widgets/queue_group.dart';

class QueueProcessingSection extends StatelessWidget {
  const QueueProcessingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    final processing = context.select(
      (QueueManagementCubit c) => c.state.processing,
    );
    final isCancelling = context.select(
      (QueueManagementCubit c) =>
          processing != null && c.state.isCancelRequested(processing.uuid),
    );

    final processIsEmpty = processing == null;

    return QueueGroup(
      accentColor: processIsEmpty ? themeColors.textTertiary : themeColors.info,
      pulse: !processIsEmpty,
      interactive: false,
      title: l10n.queueProcessingSection,
      count: processIsEmpty ? 0 : 1,
      children: [
        if (processing == null)
          QueueGroupEmpty(text: l10n.queueEmptyProcessing)
        else
          KanbanNoteTile(
            note: processing,
            statusColor: themeColors.info,
            pulse: !isCancelling,
            footerHint: isCancelling
                ? l10n.queueItemCancelling
                : l10n.queueItemProcessingSubtitle,
            footerHintColor: isCancelling
                ? themeColors.warning
                : themeColors.info,
          ),
      ],
    );
  }
}
