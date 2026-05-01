import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/adaptive/constraint/constraint_adaptive_builder.dart';
import 'package:voice_notes/core/adaptive/constraint/constraint_breakpoints.dart';
import 'package:voice_notes/core/adaptive/constraint/constraint_size_enum.dart';

void main() {
  group('ConstraintSizeEnum', () {
    test('exposes size helpers', () {
      expect(ConstraintSizeEnum.small.isSmall, isTrue);
      expect(ConstraintSizeEnum.medium.isMedium, isTrue);
      expect(ConstraintSizeEnum.large.isLarge, isTrue);
    });

    test('when falls back to nearest smaller value', () {
      expect(ConstraintSizeEnum.small.when('small'), 'small');
      expect(ConstraintSizeEnum.medium.when('small'), 'small');
      expect(
        ConstraintSizeEnum.large.when('small', medium: 'medium'),
        'medium',
      );
    });

    test('maybeWhen returns direct match or orElse', () {
      expect(
        ConstraintSizeEnum.small.maybeWhen(small: 'small', orElse: 'fallback'),
        'small',
      );
      expect(
        ConstraintSizeEnum.medium.maybeWhen(small: 'small', orElse: 'fallback'),
        'fallback',
      );
      expect(
        ConstraintSizeEnum.large.maybeWhen(large: 'large', orElse: 'fallback'),
        'large',
      );
    });

    test('whenBuilder only invokes selected builder', () {
      var calls = 0;

      final value = ConstraintSizeEnum.large.whenBuilder(
        () {
          calls++;
          return 'small';
        },
        medium: () {
          calls++;
          return 'medium';
        },
        large: () {
          calls++;
          return 'large';
        },
      );

      expect(value, 'large');
      expect(calls, 1);
    });

    test('maybeWhenBuilder only invokes selected fallback builder', () {
      var calls = 0;

      final value = ConstraintSizeEnum.medium.maybeWhenBuilder(
        small: () {
          calls++;
          return 'small';
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

  group('ConstraintBreakpoints', () {
    test('fromWidth resolves local breakpoint boundaries', () {
      const breakpoints = ConstraintBreakpoints(
        smallMaxWidth: 320,
        mediumMaxWidth: 520,
      );

      expect(breakpoints.fromWidth(320), ConstraintSizeEnum.small);
      expect(breakpoints.fromWidth(320.1), ConstraintSizeEnum.medium);
      expect(breakpoints.fromWidth(520), ConstraintSizeEnum.medium);
      expect(breakpoints.fromWidth(520.1), ConstraintSizeEnum.large);
    });

    test('fromConstraints resolves local point from maxWidth', () {
      const breakpoints = ConstraintBreakpoints(
        smallMaxWidth: 320,
        mediumMaxWidth: 520,
      );

      expect(
        breakpoints.fromConstraints(const BoxConstraints(maxWidth: 480)),
        ConstraintSizeEnum.medium,
      );
    });

    test('fromConstraints resolves unbounded width to large', () {
      const breakpoints = ConstraintBreakpoints(
        smallMaxWidth: 320,
        mediumMaxWidth: 520,
      );

      expect(
        breakpoints.fromConstraints(const BoxConstraints()),
        ConstraintSizeEnum.large,
      );
    });

    test('asserts valid breakpoint order', () {
      expect(
        () => ConstraintBreakpoints(smallMaxWidth: 520, mediumMaxWidth: 320),
        throwsAssertionError,
      );
      expect(
        () => ConstraintBreakpoints(smallMaxWidth: 320, mediumMaxWidth: 320),
        throwsAssertionError,
      );
    });

    test('asserts non-negative widths', () {
      expect(
        () => ConstraintBreakpoints(smallMaxWidth: -1, mediumMaxWidth: 320),
        throwsAssertionError,
      );
    });
  });

  group('ConstraintAdaptiveBuilder', () {
    testWidgets('uses local breakpoints from parent constraints', (
      tester,
    ) async {
      await tester.pumpWidget(
        _adaptiveApp(
          width: 1400,
          child: Center(
            child: SizedBox(
              width: 360,
              child: ConstraintAdaptiveBuilder(
                breakpoints: const ConstraintBreakpoints(
                  smallMaxWidth: 320,
                  mediumMaxWidth: 480,
                ),
                small: (context, constraints) => const Text('small'),
                medium: (context, constraints) => const Text('medium'),
                large: (context, constraints) => const Text('large'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('medium'), findsOneWidget);
      expect(find.text('small'), findsNothing);
      expect(find.text('large'), findsNothing);
      expect(find.byType(LayoutBuilder), findsOneWidget);
    });

    testWidgets('falls back to nearest smaller builder', (tester) async {
      await tester.pumpWidget(
        _adaptiveApp(
          width: 1400,
          child: Center(
            child: SizedBox(
              width: 700,
              child: ConstraintAdaptiveBuilder(
                breakpoints: const ConstraintBreakpoints(
                  smallMaxWidth: 320,
                  mediumMaxWidth: 480,
                ),
                small: (context, constraints) => const Text('small'),
                medium: (context, constraints) => const Text('medium'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('medium'), findsOneWidget);
      expect(find.text('small'), findsNothing);
    });

    testWidgets('passes current constraints into selected builder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _adaptiveApp(
          width: 1400,
          child: Center(
            child: SizedBox(
              width: 420,
              child: ConstraintAdaptiveBuilder(
                breakpoints: const ConstraintBreakpoints(
                  smallMaxWidth: 320,
                  mediumMaxWidth: 480,
                ),
                small: (context, constraints) =>
                    Text('small ${constraints.maxWidth.toStringAsFixed(0)}'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('small 420'), findsOneWidget);
    });

    testWidgets('only invokes selected builder once', (tester) async {
      var smallCalls = 0;
      var mediumCalls = 0;
      var largeCalls = 0;

      await tester.pumpWidget(
        _adaptiveApp(
          width: 1400,
          child: Center(
            child: SizedBox(
              width: 700,
              child: ConstraintAdaptiveBuilder(
                breakpoints: const ConstraintBreakpoints(
                  smallMaxWidth: 320,
                  mediumMaxWidth: 480,
                ),
                small: (context, constraints) {
                  smallCalls++;
                  return const Text('small');
                },
                medium: (context, constraints) {
                  mediumCalls++;
                  return const Text('medium');
                },
                large: (context, constraints) {
                  largeCalls++;
                  return const Text('large');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('large'), findsOneWidget);
      expect(smallCalls, 0);
      expect(mediumCalls, 0);
      expect(largeCalls, 1);
    });
  });
}

Widget _adaptiveApp({required double width, required Widget child}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}
