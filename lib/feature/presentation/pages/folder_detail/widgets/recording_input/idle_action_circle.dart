part of 'recording_input.dart';

/// Главная action-кнопка idle-состояния (32×32) с accent-фоном и glow.
/// Иконка mic / send переключается с анимацией в зависимости от наличия текста.
class _IdleActionCircle extends StatelessWidget {
  final bool hasText;
  final Color backgroundColor;
  final Color iconColor;
  final Color glowColor;
  final VoidCallback? onSend;
  final VoidCallback? onStartRecording;

  const _IdleActionCircle({
    required this.hasText,
    required this.backgroundColor,
    required this.iconColor,
    required this.glowColor,
    this.onSend,
    this.onStartRecording,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasText ? onSend : onStartRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            hasText ? Icons.send : Icons.mic,
            key: ValueKey(hasText),
            color: iconColor,
            size: AppSizes.iconSmall,
          ),
        ),
      ),
    );
  }
}
