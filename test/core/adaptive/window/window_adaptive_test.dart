import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/adaptive/window/adaptive_branch.dart';
import 'package:voice_notes/core/adaptive/window/adaptive_content_width.dart';
import 'package:voice_notes/core/adaptive/window/app_window_class.dart';
import 'package:voice_notes/core/adaptive/window/app_window_size_enum.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/folder_detail_adaptive.dart';
import 'package:voice_notes/feature/presentation/pages/folders/screens/folders_adaptive_scaffold.dart';

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
    test('BoxConstraints exposes windowWidthSize', () {
      const constraints = BoxConstraints(maxWidth: 700);

      expect(constraints.windowWidthSize, AppWindowSizeEnum.medium);
    });

    test('BoxConstraints exposes windowClass', () {
      const constraints = BoxConstraints(maxWidth: 844, maxHeight: 390);

      expect(constraints.windowClass.widthSize, AppWindowSizeEnum.expanded);
      expect(constraints.windowClass.heightSize, AppWindowSizeEnum.compact);
    });

    testWidgets('BuildContext exposes windowWidthSize from MediaQuery', (
      tester,
    ) async {
      late AppWindowSizeEnum windowWidthSize;
      late AppWindowClass windowClass;

      await tester.pumpWidget(
        _adaptiveApp(
          width: 841,
          height: 390,
          child: Builder(
            builder: (context) {
              windowWidthSize = context.windowWidthSize;
              windowClass = context.windowClass;

              return Text(
                '${windowWidthSize.name}/${windowClass.heightSize.name}',
              );
            },
          ),
        ),
      );

      expect(windowWidthSize, AppWindowSizeEnum.expanded);
      expect(windowClass.heightSize, AppWindowSizeEnum.compact);
      expect(find.text('expanded/compact'), findsOneWidget);
    });
  });

  group('AdaptiveBranch', () {
    testWidgets('uses full MediaQuery width', (tester) async {
      await tester.pumpWidget(
        _adaptiveApp(
          width: 1200.1,
          height: 390,
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
          height: 390,
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
          height: 390,
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

      expect(constrainedBox.constraints.maxWidth, 760);
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

  group('FolderDetailAdaptive', () {
    test('does not center content on compact-height landscape phones', () {
      final phoneLandscape = AppWindowClass.fromSize(const Size(844, 390));
      final tabletPortrait = AppWindowClass.fromSize(const Size(700, 960));

      expect(FolderDetailAdaptive.useCenteredContent(phoneLandscape), isFalse);
      expect(FolderDetailAdaptive.useCenteredContent(tabletPortrait), isTrue);
    });
  });

  group('FoldersAdaptiveScaffold', () {
    test('requires enough height and pane width for split view', () {
      expect(
        FoldersAdaptiveScaffold.canUseWorkspaceLayout(
          const BoxConstraints(
            maxWidth: AppSizes.workspaceMinWidth,
            maxHeight: 700,
          ),
        ),
        isTrue,
      );
      expect(
        FoldersAdaptiveScaffold.canUseWorkspaceLayout(
          const BoxConstraints(maxWidth: 844, maxHeight: 390),
        ),
        isFalse,
      );
      expect(
        FoldersAdaptiveScaffold.canUseWorkspaceLayout(
          const BoxConstraints(
            maxWidth: AppSizes.workspaceMinWidth - 1,
            maxHeight: 700,
          ),
        ),
        isFalse,
      );
    });
  });
}

Widget _adaptiveApp({
  required double width,
  required Widget child,
  double height = 800,
}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, height)),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}
