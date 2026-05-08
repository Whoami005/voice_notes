import 'package:flutter/widgets.dart';

class AdaptiveContentWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;

  const AdaptiveContentWidth({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.maxWidth = 960,
    super.key,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
