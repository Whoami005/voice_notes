import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AppVisibilityInfo {
  final double visibleFraction;
  final Size size;
  final Rect visibleBounds;

  const AppVisibilityInfo({
    required this.visibleFraction,
    required this.size,
    required this.visibleBounds,
  });

  bool get isVisible => visibleFraction > 0;
}

typedef AppVisibilityChanged = void Function(AppVisibilityInfo info);

class AppVisibilityDetector extends StatelessWidget {
  final Key detectorKey;
  final AppVisibilityChanged? onVisibilityChanged;
  final Widget child;

  const AppVisibilityDetector({
    required this.detectorKey,
    required this.child,
    this.onVisibilityChanged,
  }) : super(key: detectorKey);

  @override
  Widget build(BuildContext context) {
    final callback = onVisibilityChanged;

    return VisibilityDetector(
      key: detectorKey,
      onVisibilityChanged: callback == null
          ? null
          : (info) => callback(
              AppVisibilityInfo(
                visibleFraction: info.visibleFraction,
                size: info.size,
                visibleBounds: info.visibleBounds,
              ),
            ),
      child: child,
    );
  }
}
