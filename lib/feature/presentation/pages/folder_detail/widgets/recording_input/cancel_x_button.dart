part of 'recording_input.dart';

/// 32×32 призрачный X-tap для отмены записи. Без фона, только иконка.
class _CancelXButton extends StatelessWidget {
  final Color color;
  final VoidCallback? onTap;

  const _CancelXButton({required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppSizes.actionCircleSize,
        height: AppSizes.actionCircleSize,
        child: Icon(Icons.close, size: AppSizes.iconSmall, color: color),
      ),
    );
  }
}
