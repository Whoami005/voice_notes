import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/main_shell.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_bottom_nav.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

void main() {
  testWidgets('renders active branch without root navigation chrome', (
    tester,
  ) async {
    await _pumpMainShell(tester, width: 600);

    expect(find.text('folders-branch'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);
  });

  testWidgets('does not show navigation rail on medium width', (tester) async {
    await _pumpMainShell(tester, width: 700);

    expect(find.byType(AppBottomNav), findsNothing);
  });

  testWidgets('main navigation scope switches branch', (tester) async {
    await _pumpMainShell(tester, width: 700);

    expect(find.text('folders-branch'), findsOneWidget);

    await tester.tap(find.text('open-settings'));
    await tester.pumpAndSettle();

    expect(find.text('settings-branch'), findsOneWidget);
    expect(find.text('folders-branch'), findsNothing);
  });
}

Future<void> _pumpMainShell(WidgetTester tester, {required double width}) {
  final router = GoRouter(
    initialLocation: '/folders',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/folders',
                builder: (context, state) => const _FoldersBranchProbe(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings/general',
                builder: (context, state) =>
                    const Scaffold(body: Text('settings-branch')),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
}

class _FoldersBranchProbe extends StatelessWidget {
  const _FoldersBranchProbe();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('folders-branch'),
          TextButton(
            onPressed: () => MainNavigationScope.of(context).goBranch(1),
            child: const Text('open-settings'),
          ),
        ],
      ),
    );
  }
}
