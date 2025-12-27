import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/root_scaffold.dart';
import 'package:voice_notes/core/packages/app_router/routes.dart';
import 'package:voice_notes/feature/presentation/pages/folders/screens/folders_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/screens/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.folders,
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return RootScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Folders
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.folders,
              builder: (context, state) => const FoldersScreen(),
            ),
          ],
        ),
        // Branch 1: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
