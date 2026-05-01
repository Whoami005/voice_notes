import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/adaptive/window/adaptive_branch.dart';
import 'package:voice_notes/core/adaptive/window/adaptive_content_width.dart';
import 'package:voice_notes/core/adaptive/window/app_adaptive_policy.dart';
import 'package:voice_notes/core/adaptive/window/app_window_size_enum.dart';

void main() {
  group('AppWindowSizeEnum', () {
    test('fromWidth resolves breakpoint boundaries', () {
      expect(AppWindowSizeEnum.fromWidth(600), AppWindowSizeEnum.compact);
      expect(AppWindowSizeEnum.fromWidth(600.1), AppWindowSizeEnum.medium);
      expect(AppWindowSizeEnum.fromWidth(840), AppWindowSizeEnum.medium);
      expect(AppWindowSizeEnum.fromWidth(840.1), AppWindowSizeEnum.expanded);
      expect(AppWindowSizeEnum.fromWidth(1200), AppWindowSizeEnum.expanded);
      expect(AppWindowSizeEnum.fromWidth(1200.1), AppWindowSizeEnum.large);
    });

    test('fromConstraints resolves point from maxWidth', () {
      expect(
        AppWindowSizeEnum.fromConstraints(const BoxConstraints(maxWidth: 320)),
        AppWindowSizeEnum.compact,
      );
      expect(
        AppWindowSizeEnum.fromConstraints(const BoxConstraints(maxWidth: 700)),
        AppWindowSizeEnum.medium,
      );
      expect(
        AppWindowSizeEnum.fromConstraints(const BoxConstraints(maxWidth: 1100)),
        AppWindowSizeEnum.expanded,
      );
      expect(
        AppWindowSizeEnum.fromConstraints(const BoxConstraints(maxWidth: 1600)),
        AppWindowSizeEnum.large,
      );
    });

    test('fromConstraints resolves unbounded width to large', () {
      expect(
        AppWindowSizeEnum.fromConstraints(const BoxConstraints()),
        AppWindowSizeEnum.large,
      );
    });

    test('fromWidth asserts on negative values', () {
      expect(() => AppWindowSizeEnum.fromWidth(-1), throwsAssertionError);
    });

    test('exposes size helpers', () {
      expect(AppWindowSizeEnum.compact.isCompact, isTrue);
      expect(AppWindowSizeEnum.medium.isMedium, isTrue);
      expect(AppWindowSizeEnum.expanded.isExpanded, isTrue);
      expect(AppWindowSizeEnum.large.isLarge, isTrue);
      expect(AppWindowSizeEnum.compact.isCompactOnly, isTrue);
      expect(AppWindowSizeEnum.medium.isMediumOrLarger, isTrue);
      expect(AppWindowSizeEnum.expanded.isExpandedOrLarger, isTrue);
      expect(AppWindowSizeEnum.large.isExpandedOrLarger, isTrue);
    });

    test('when falls back to nearest smaller value', () {
      expect(AppWindowSizeEnum.compact.when('compact'), 'compact');
      expect(AppWindowSizeEnum.medium.when('compact'), 'compact');
      expect(
        AppWindowSizeEnum.expanded.when('compact', medium: 'medium'),
        'medium',
      );
      expect(
        AppWindowSizeEnum.large.when('compact', expanded: 'expanded'),
        'expanded',
      );
    });

    test('maybeWhen returns direct match or orElse', () {
      expect(
        AppWindowSizeEnum.compact.maybeWhen(
          compact: 'compact',
          orElse: 'fallback',
        ),
        'compact',
      );
      expect(
        AppWindowSizeEnum.medium.maybeWhen(
          compact: 'compact',
          orElse: 'fallback',
        ),
        'fallback',
      );
      expect(
        AppWindowSizeEnum.large.maybeWhen(large: 'large', orElse: 'fallback'),
        'large',
      );
    });

    test('whenBuilder only invokes selected builder', () {
      var calls = 0;

      final value = AppWindowSizeEnum.expanded.whenBuilder(
        () {
          calls++;
          return 'compact';
        },
        medium: () {
          calls++;
          return 'medium';
        },
        expanded: () {
          calls++;
          return 'expanded';
        },
        large: () {
          calls++;
          return 'large';
        },
      );

      expect(value, 'expanded');
      expect(calls, 1);
    });

    test('maybeWhenBuilder only invokes selected fallback builder', () {
      var calls = 0;

      final value = AppWindowSizeEnum.expanded.maybeWhenBuilder(
        compact: () {
          calls++;
          return 'compact';
        },
        orElse: () {
          calls++;
          return 'fallback';
        },
      );

      expect(value, 'fallback');
      expect(calls, 1);
    });
  });

  group('window size extensions', () {
    test('BoxConstraints exposes windowSize', () {
      const constraints = BoxConstraints(maxWidth: 700);

      expect(constraints.windowSize, AppWindowSizeEnum.medium);
    });

    testWidgets('BuildContext exposes windowSize from MediaQuery', (
      tester,
    ) async {
      late AppWindowSizeEnum windowSize;

      await tester.pumpWidget(
        _adaptiveApp(
          width: 841,
          child: Builder(
            builder: (context) {
              windowSize = context.windowSize;

              return Text(windowSize.name);
            },
          ),
        ),
      );

      expect(windowSize, AppWindowSizeEnum.expanded);
      expect(find.text('expanded'), findsOneWidget);
    });
  });

  group('AdaptiveBranch', () {
    testWidgets('uses full MediaQuery width', (tester) async {
      await tester.pumpWidget(
        _adaptiveApp(
          width: 1200.1,
          child: AdaptiveBranch(
            compact: (context) => const Text('compact'),
            medium: (context) => const Text('medium'),
            expanded: (context) => const Text('expanded'),
            large: (context) => const Text('large'),
          ),
        ),
      );

      expect(find.text('large'), findsOneWidget);
      expect(find.text('expanded'), findsNothing);
      expect(find.byType(LayoutBuilder), findsNothing);
    });

    testWidgets('falls back to nearest smaller builder', (tester) async {
      await tester.pumpWidget(
        _adaptiveApp(
          width: 900,
          child: AdaptiveBranch(
            compact: (context) => const Text('compact'),
            medium: (context) => const Text('medium'),
          ),
        ),
      );

      expect(find.text('medium'), findsOneWidget);
      expect(find.text('compact'), findsNothing);
    });

    testWidgets('only invokes selected builder once', (tester) async {
      var compactCalls = 0;
      var mediumCalls = 0;
      var expandedCalls = 0;

      await tester.pumpWidget(
        _adaptiveApp(
          width: 700,
          child: AdaptiveBranch(
            compact: (context) {
              compactCalls++;
              return const Text('compact');
            },
            medium: (context) {
              mediumCalls++;
              return const Text('medium');
            },
            expanded: (context) {
              expandedCalls++;
              return const Text('expanded');
            },
          ),
        ),
      );

      expect(find.text('medium'), findsOneWidget);
      expect(compactCalls, 0);
      expect(mediumCalls, 1);
      expect(expandedCalls, 0);
    });
  });

  group('AdaptiveContentWidth', () {
    testWidgets('applies default max width', (tester) async {
      await tester.pumpWidget(
        _adaptiveApp(
          width: 1400,
          child: const AdaptiveContentWidth(child: SizedBox()),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );

      expect(constrainedBox.constraints.maxWidth, 960);
    });

    testWidgets('applies custom max width', (tester) async {
      await tester.pumpWidget(
        _adaptiveApp(
          width: 1400,
          child: const AdaptiveContentWidth(maxWidth: 720, child: SizedBox()),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );

      expect(constrainedBox.constraints.maxWidth, 720);
    });
  });

  group('AppAdaptivePolicy', () {
    test('returns compact-specific navigation policy', () {
      expect(
        AppAdaptivePolicy.useBottomNavigation(AppWindowSizeEnum.compact),
        isTrue,
      );
      expect(
        AppAdaptivePolicy.useNavigationRail(AppWindowSizeEnum.compact),
        isFalse,
      );
      expect(
        AppAdaptivePolicy.useCenteredContent(AppWindowSizeEnum.compact),
        isFalse,
      );
      expect(
        AppAdaptivePolicy.useSplitView(AppWindowSizeEnum.compact),
        isFalse,
      );
    });

    test('returns large-screen policy for expanded and larger widths', () {
      expect(
        AppAdaptivePolicy.useNavigationRail(AppWindowSizeEnum.medium),
        isTrue,
      );
      expect(
        AppAdaptivePolicy.useCenteredContent(AppWindowSizeEnum.expanded),
        isTrue,
      );
      expect(AppAdaptivePolicy.useSplitView(AppWindowSizeEnum.large), isTrue);
    });
  });
}

Widget _adaptiveApp({required double width, required Widget child}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}
