part of 'note_bubble.dart';

class _StatusAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _StatusAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
}

class _StatusActionButton extends StatelessWidget {
  final _StatusAction action;

  const _StatusActionButton({required this.action, super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: AppSizes.p16),
      label: Text(action.label),
      style: TextButton.styleFrom(
        foregroundColor: action.color,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p6,
        ),
      ),
    );
  }
}
