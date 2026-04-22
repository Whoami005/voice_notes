part of 'note_bubble.dart';

class _TranscribingViewData extends Equatable {
  final bool supportsInteractiveProgress;
  final bool supportsCancellation;
  final AsrTranscribeProgress? progress;
  final String? previewText;

  const _TranscribingViewData({
    required this.supportsInteractiveProgress,
    required this.supportsCancellation,
    required this.progress,
    required this.previewText,
  });

  factory _TranscribingViewData.fromSnapshot(
    TranscriptionQueueSnapshot snapshot,
    String noteUid,
  ) {
    if (snapshot.processing != noteUid) {
      return const _TranscribingViewData(
        supportsInteractiveProgress: false,
        supportsCancellation: false,
        progress: null,
        previewText: null,
      );
    }

    final progress = snapshot.processingProgress;

    return _TranscribingViewData(
      supportsInteractiveProgress:
          snapshot.processingSupportsInteractiveProgress,
      supportsCancellation: snapshot.processingSupportsCancellation,
      progress: progress,
      previewText: _normalizePreviewText(progress?.partialText),
    );
  }

  static String? _normalizePreviewText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;

    return normalized;
  }

  @override
  List<Object?> get props => [
    supportsInteractiveProgress,
    supportsCancellation,
    progress,
    previewText,
  ];
}

class _InteractiveTranscribingRow extends StatelessWidget {
  final AsrTranscribeProgress? progress;
  final String? previewText;
  final String fallbackLabel;
  final _StatusAction? cancelAction;

  const _InteractiveTranscribingRow({
    required this.progress,
    required this.previewText,
    required this.fallbackLabel,
    required this.cancelAction,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final progressValue = progress?.progress;
    final percentLabel = progress != null
        ? l10n.noteStatusTranscribingProgress(progress!.percent)
        : fallbackLabel;

    return AnimatedSize(
      duration: _statusContentAnimationDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            percentLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: themeColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          AppSpacer.p8,
          LinearProgressIndicator(
            key: const Key('note-bubble-progress-bar'),
            value: progressValue,
            minHeight: AppSizes.strokeMedium,
            color: themeColors.accentPrimary,
            backgroundColor: themeColors.bgPrimary,
          ),
          AnimatedSwitcher(
            duration: _previewFadeDuration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: switch (previewText) {
              final preview? => Padding(
                key: ValueKey(preview),
                padding: const EdgeInsets.only(top: AppSizes.p8),
                child: _LivePreviewCard(text: preview),
              ),
              null => const SizedBox.shrink(),
            },
          ),
          if (cancelAction != null) ...[
            AppSpacer.p8,
            Align(
              alignment: Alignment.centerLeft,
              child: _StatusActionButton(
                key: const Key('note-bubble-cancel-button'),
                action: cancelAction!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LivePreviewCard extends StatelessWidget {
  final String text;

  const _LivePreviewCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: themeColors.bgPrimary.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSizes.p12),
        border: Border.all(
          color: themeColors.borderPrimary.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p10,
        ),
        child: Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: themeColors.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
