import 'package:flutter/material.dart';

class BasePopScope extends StatelessWidget {
  final Widget child;
  final bool Function(BuildContext context) canPop;
  final void Function()? onPopInvokedWithResult;

  const BasePopScope({
    required this.canPop,
    required this.child,
    super.key,
    this.onPopInvokedWithResult,
  });

  @override
  Widget build(BuildContext context) {
    final isCanPop = canPop(context);

    return PopScope(
      canPop: isCanPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isCanPop) {
          onPopInvokedWithResult?.call();
        }
      },
      child: child,
    );
  }
}
