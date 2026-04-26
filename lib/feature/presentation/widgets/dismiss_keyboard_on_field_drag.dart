import 'package:flutter/material.dart';

class DismissKeyboardOnFieldDrag extends StatefulWidget {
  const DismissKeyboardOnFieldDrag({
    required this.child,
    required this.focusNode,
    super.key,
    this.dragThreshold = 12,
    this.onlyDownSwipe = false,
  });

  final Widget child;
  final FocusNode focusNode;
  final double dragThreshold;

  /// true — скрывать только при свайпе вниз.
  /// false — скрывать при любом вертикальном drag.
  final bool onlyDownSwipe;

  @override
  State<DismissKeyboardOnFieldDrag> createState() =>
      _DismissKeyboardOnFieldDragState();
}

class _DismissKeyboardOnFieldDragState
    extends State<DismissKeyboardOnFieldDrag> {
  Offset? _startPosition;
  int? _pointer;
  bool _dismissed = false;

  void _reset() {
    _startPosition = null;
    _pointer = null;
    _dismissed = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,

      onPointerDown: (event) {
        _startPosition = event.position;
        _pointer = event.pointer;
        _dismissed = false;
      },

      onPointerMove: (event) {
        if (_dismissed) return;
        if (_pointer != event.pointer) return;
        if (_startPosition == null) return;

        final delta = event.position - _startPosition!;

        final isMostlyVertical =
            delta.dy.abs() > widget.dragThreshold &&
            delta.dy.abs() > delta.dx.abs();

        final shouldDismiss = widget.onlyDownSwipe
            ? isMostlyVertical && delta.dy > widget.dragThreshold
            : isMostlyVertical;

        if (shouldDismiss && widget.focusNode.hasFocus) {
          widget.focusNode.unfocus();
          _dismissed = true;
        }
      },

      onPointerUp: (_) => _reset(),
      onPointerCancel: (_) => _reset(),

      child: widget.child,
    );
  }
}
