import 'package:flutter/widgets.dart';

class AdaptiveContentWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const AdaptiveContentWidth({
    required this.child,
    this.maxWidth = 960,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
