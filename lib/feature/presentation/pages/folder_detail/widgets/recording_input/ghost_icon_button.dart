part of 'recording_input.dart';

/// Маленькая призрачная иконка-кнопка 32×32 без фона.
/// Используется для attach внутри idle-капсулы.
class _GhostIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _GhostIconButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, size: AppSizes.iconMedium, color: color),
      ),
    );
  }
}
