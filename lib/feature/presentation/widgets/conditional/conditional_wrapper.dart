import 'package:flutter/material.dart';

/// Wrapper builder.
typedef WrapperBuilder = Widget Function(Widget child);

class ConditionalWrapper extends StatelessWidget {
  final bool condition;
  final WrapperBuilder onAddWrapper;
  final Widget child;

  const ConditionalWrapper({
    required this.condition,
    required this.onAddWrapper,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return condition ? onAddWrapper(child) : child;
  }
}
