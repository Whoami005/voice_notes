import 'package:flutter/widgets.dart';
import 'package:voice_notes/core/adaptive/constraint/constraint_breakpoints.dart';

typedef ConstraintAdaptiveWidgetBuilder =
    Widget Function(BuildContext context, BoxConstraints constraints);

class ConstraintAdaptiveBuilder extends StatelessWidget {
  final ConstraintBreakpoints breakpoints;
  final ConstraintAdaptiveWidgetBuilder small;
  final ConstraintAdaptiveWidgetBuilder? medium;
  final ConstraintAdaptiveWidgetBuilder? large;

  const ConstraintAdaptiveBuilder({
    required this.breakpoints,
    required this.small,
    this.medium,
    this.large,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = breakpoints.fromConstraints(constraints);

        return size.whenBuilder(
          () => small(context, constraints),
          medium: medium == null ? null : () => medium!(context, constraints),
          large: large == null ? null : () => large!(context, constraints),
        );
      },
    );
  }
}
