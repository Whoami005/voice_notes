part of 'model_card.dart';

class _ModelIcon extends StatelessWidget {
  final String engine;

  const _ModelIcon({required this.engine});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final isWhisper = engine.toLowerCase().contains('whisper');
    final color = isWhisper ? themeColors.success : themeColors.info;

    return Container(
      width: AppSizes.avatarMedium,
      height: AppSizes.avatarMedium,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Icon(
        isWhisper ? Icons.graphic_eq : Icons.memory,
        color: color,
        size: AppSizes.iconLarge,
      ),
    );
  }
}
