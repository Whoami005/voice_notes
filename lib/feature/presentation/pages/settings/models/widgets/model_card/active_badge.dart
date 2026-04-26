part of 'model_card.dart';

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p2,
      ),
      decoration: BoxDecoration(
        color: themeColors.accentPrimary,
        borderRadius: BorderRadius.circular(AppSizes.p10),
      ),
      child: Text(
        context.l10n.modelCardActive,
        style: AppTypography.micro.copyWith(
          color: themeColors.textInverse,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
