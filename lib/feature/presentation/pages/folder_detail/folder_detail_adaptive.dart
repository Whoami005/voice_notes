import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:voice_notes/core/adaptive/adaptive.dart';

abstract final class FolderDetailAdaptive {
  static const double contentMaxWidth = 920;
  static const double recordingBarMaxWidth = 600;

  static const ConstraintBreakpoints _noteBubbleBreakpoints =
      ConstraintBreakpoints(smallMaxWidth: 480, mediumMaxWidth: 760);

  static bool useCenteredContent(AppWindowSizeEnum size) =>
      AppAdaptivePolicy.useCenteredContent(size);

  static double noteBubbleMaxWidth(BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return 720;

    final availableWidth = constraints.maxWidth;

    return _noteBubbleBreakpoints
        .fromConstraints(constraints)
        .when(
          availableWidth * 0.94,
          medium: math.min(availableWidth * 0.88, 640),
          large: math.min(availableWidth * 0.78, 720),
        );
  }
}
