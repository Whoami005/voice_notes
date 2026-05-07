import 'package:flutter/material.dart';

class NoteSeparatedColumn extends StatelessWidget {
  final List<Widget> children;
  final bool showLeadingDivider;

  const NoteSeparatedColumn({
    required this.children,
    this.showLeadingDivider = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLeadingDivider) const Divider(height: 1),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}
