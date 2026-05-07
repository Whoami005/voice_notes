import 'package:flutter/widgets.dart';

class AdaptiveContentWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  final AlignmentGeometry alignment;

  const AdaptiveContentWidth({
    required this.child,
    this.maxWidth = 960,
    super.key,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
