import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';

class QueueGroup extends StatefulWidget {
  final Color accentColor;
  final bool pulse;
  final String title;
  final int count;
  final Color? countColor;
  final bool defaultExpanded;
  final bool interactive;
  final List<Widget> actions;
  final List<Widget> children;

  const QueueGroup({
    required this.accentColor,
    required this.title,
    required this.count,
    this.children = const [],
    this.actions = const [],
    this.defaultExpanded = true,
    this.interactive = true,
    this.pulse = false,
    this.countColor,
    super.key,
  });

  @override
  State<QueueGroup> createState() => _QueueGroupState();
}

class _QueueGroupState extends State<QueueGroup>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.defaultExpanded;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.pulse) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(QueueGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse) {
      if (widget.pulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController
          ..stop()
          ..value = 0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccentBar(
                color: widget.accentColor,
                pulse: widget.pulse,
                controller: _pulseController,
              ),
              Expanded(
                child: Container(
                  color: themeColors.bgSecondary,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.p12,
                    AppSizes.p10,
                    AppSizes.p8,
                    AppSizes.p12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _QueueGroupHeader(
                        title: widget.title,
                        count: widget.count,
                        countColor: widget.countColor,
                        isExpanded: _expanded,
                        onToggle: widget.interactive
                            ? () => setState(() => _expanded = !_expanded)
                            : null,
                      ),
                      if (_expanded && widget.actions.isNotEmpty) ...[
                        AppSpacer.p6,
                        Wrap(
                          spacing: AppSizes.p2,
                          runSpacing: AppSizes.p2,
                          children: widget.actions,
                        ),
                      ],
                      if (_expanded) ...[AppSpacer.p4, ...widget.children],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentBar extends StatelessWidget {
  final Color color;
  final bool pulse;
  final AnimationController controller;

  const _AccentBar({
    required this.color,
    required this.pulse,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final opacity = pulse ? 0.55 + 0.45 * (1 - controller.value) : 1.0;

        return Container(width: 4, color: color.withValues(alpha: opacity));
      },
    );
  }
}

class _QueueGroupHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color? countColor;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const _QueueGroupHeader({
    required this.title,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppSizes.p4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              size: AppSizes.iconSmall,
              color: themeColors.textTertiary,
            ),
            AppSpacer.p4,
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: AppTypography.caption.copyWith(
                color: countColor ?? themeColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacer.p4,
          ],
        ),
      ),
    );
  }
}

class QueueGroupEmpty extends StatelessWidget {
  final String text;

  const QueueGroupEmpty({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(color: themeColors.textTertiary),
      ),
    );
  }
}

class QueueHeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const QueueHeaderAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(icon, size: AppSizes.iconSmall, color: color),
      label: Text(label, style: AppTypography.caption.copyWith(color: color)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p8,
          vertical: AppSizes.p4,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }
}
