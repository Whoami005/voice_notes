import 'package:flutter/widgets.dart';
import 'package:voice_notes/core/adaptive/window/app_window_size_enum.dart';

typedef AdaptiveWidgetBuilder = Widget Function(BuildContext context);

class AdaptiveBranch extends StatelessWidget {
  final AdaptiveWidgetBuilder compact;
  final AdaptiveWidgetBuilder? medium;
  final AdaptiveWidgetBuilder? expanded;
  final AdaptiveWidgetBuilder? large;

  const AdaptiveBranch({
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final windowSize = context.windowSize;

    return windowSize.whenBuilder(
      () => compact(context),
      medium: medium == null ? null : () => medium!(context),
      expanded: expanded == null ? null : () => expanded!(context),
      large: large == null ? null : () => large!(context),
    );
  }
}
