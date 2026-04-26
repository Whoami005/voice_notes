part of 'model_card.dart';

class _ModelRecommendationSection extends StatelessWidget {
  final AsrModelEntity model;

  const _ModelRecommendationSection({required this.model});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;
    final text = model.supportsStreaming
        ? l10n.modelTipStreamingForLongRecords
        : l10n.modelTipOfflineShortRecords;

    return Row(
      key: const Key('model-card-recommendation'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSizes.p8,
      children: [
        Icon(
          Icons.info_outline,
          size: AppSizes.p16,
          color: themeColors.textTertiary,
        ),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
