import 'package:flutter/widgets.dart';
import 'package:voice_notes/core/adaptive/window/app_window_size_enum.dart';

final class AppWindowClass {
  final Size size;

  const AppWindowClass._(this.size);

  factory AppWindowClass.fromContext(BuildContext context) {
    return AppWindowClass.fromSize(MediaQuery.sizeOf(context));
  }

  factory AppWindowClass.fromConstraints(BoxConstraints constraints) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : double.infinity;
    final height = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : double.infinity;

    return AppWindowClass.fromSize(Size(width, height));
  }

  factory AppWindowClass.fromSize(Size size) {
    assert(size.width >= 0, 'width must be non-negative');
    assert(size.height >= 0, 'height must be non-negative');

    return AppWindowClass._(size);
  }

  AppWindowSizeEnum get heightSize =>
      AppWindowSizeEnum.fromDimension(size.height);

  AppWindowSizeEnum get widthSize =>
      AppWindowSizeEnum.fromDimension(size.width);
}

extension AppWindowClassBuildContextExtension on BuildContext {
  AppWindowClass get windowClass => AppWindowClass.fromContext(this);
}

extension AppWindowClassConstraintsExtension on BoxConstraints {
  AppWindowClass get windowClass => AppWindowClass.fromConstraints(this);
}
