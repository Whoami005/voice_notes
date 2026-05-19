import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/adaptive/adaptive.dart' as adaptive;

void main() {
  test('adaptive barrel exports window API', () {
    expect(
      adaptive.AppWindowSizeEnum.fromWidth(600),
      adaptive.AppWindowSizeEnum.compact,
    );
    expect(
      adaptive.AppWindowClass.fromSize(const Size(700, 390)).heightSize,
      adaptive.AppWindowSizeEnum.compact,
    );
    expect(adaptive.AdaptiveBranch, isNotNull);
    expect(adaptive.AdaptiveContentWidth, isNotNull);
    expect(adaptive.WorkspaceLayoutPolicy, isNotNull);
  });

  test('adaptive barrel exports constraint API', () {
    const breakpoints = adaptive.ConstraintBreakpoints(
      smallMaxWidth: 320,
      mediumMaxWidth: 520,
    );

    expect(breakpoints.fromWidth(521), adaptive.ConstraintSizeEnum.large);
    expect(adaptive.ConstraintAdaptiveBuilder, isNotNull);
  });
}
