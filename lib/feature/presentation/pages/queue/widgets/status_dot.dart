import 'package:flutter/material.dart';

class StatusDot extends StatefulWidget {
  final Color color;
  final bool pulse;

  const StatusDot({required this.color, this.pulse = false, super.key});

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse) {
      if (widget.pulse) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl
          ..stop()
          ..value = 0;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final glow = widget.pulse ? 4 + 4 * _ctrl.value : 0.0;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: widget.pulse
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.45),
                      blurRadius: glow,
                      spreadRadius: glow / 3,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
