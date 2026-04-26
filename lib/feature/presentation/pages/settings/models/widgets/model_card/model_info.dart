part of 'model_card.dart';

class _ModelInfo extends StatelessWidget {
  final AsrModelEntity model;

  const _ModelInfo({required this.model});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final languageLabel = LocalizedModels.languageLabel(
      model.uuid,
      context.l10n,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSizes.p2,
      children: [
        Text(
          model.name,
          style: AppTypography.h3.copyWith(color: themeColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${model.engine} • ${model.size}',
          style: AppTypography.caption.copyWith(
            color: themeColors.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (languageLabel != null)
          Text(
            languageLabel,
            style: AppTypography.caption.copyWith(
              color: themeColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
