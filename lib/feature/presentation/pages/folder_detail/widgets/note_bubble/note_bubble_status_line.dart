part of 'note_bubble.dart';

class _StatusLine extends StatelessWidget {
  final IconData? icon;
  final bool showSpinner;
  final String label;
  final Color color;
  final bool italic;
  final _StatusAction? action;

  const _StatusLine({
    required this.label,
    required this.color,
    this.icon,
    this.showSpinner = false,
    this.italic = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final action = this.action;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: AppSizes.p8,
          children: [
            if (showSpinner)
              SizedBox(
                width: AppSizes.p16,
                height: AppSizes.p16,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.strokeThin,
                  color: color,
                ),
              )
            else if (icon != null)
              Icon(icon, size: AppSizes.p16, color: color),
            Flexible(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontStyle: italic ? FontStyle.italic : null,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        if (action != null) ...[
          AppSpacer.p8,
          Align(
            alignment: Alignment.centerLeft,
            child: _StatusActionButton(action: action),
          ),
        ],
      ],
    );
  }
}
