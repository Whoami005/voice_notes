part of 'recording_input.dart';

/// 32×32 accent-кнопка отправки записи с glow-тенью.
class _SendCircle extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final Color glowColor;
  final VoidCallback? onTap;

  const _SendCircle({
    required this.backgroundColor,
    required this.iconColor,
    required this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(Icons.send, size: AppSizes.iconSmall, color: iconColor),
      ),
    );
  }
}
