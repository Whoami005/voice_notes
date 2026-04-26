part of 'model_card.dart';

class _CapabilityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CapabilityChip({required this.icon, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: themeColors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSizes.p6,
        children: [
          Icon(icon, size: AppSizes.p14, color: themeColors.accentPrimary),
          Text(
            label,
            style: AppTypography.micro.copyWith(
              color: themeColors.accentPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
