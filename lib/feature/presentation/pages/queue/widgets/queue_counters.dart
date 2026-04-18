import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';

class QueueCountersGrid extends StatelessWidget {
  final int processing;
  final int queued;
  final int failed;
  final int cancelled;

  const QueueCountersGrid({
    required this.processing,
    required this.queued,
    required this.failed,
    required this.cancelled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.only(top: AppSizes.p12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: themeColors.bgTertiary)),
      ),
      child: Row(
        children: [
          QueueCounter(
            label: l10n.queueCounterLabelProcessing,
            value: processing,
            color: themeColors.info,
          ),
          QueueCounter(
            label: l10n.queueCounterLabelQueued,
            value: queued,
            color: themeColors.textPrimary,
          ),
          QueueCounter(
            label: l10n.queueCounterLabelFailed,
            value: failed,
            color: failed == 0 ? themeColors.textPrimary : themeColors.error,
          ),
          QueueCounter(
            label: l10n.queueCounterLabelCancelled,
            value: cancelled,
            color: themeColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class QueueCounter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const QueueCounter({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: themeColors.textTertiary,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
          AppSpacer.p2,
          Text(
            '$value',
            style: AppTypography.h2.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
