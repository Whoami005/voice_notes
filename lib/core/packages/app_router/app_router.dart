import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/root_screen.dart';
import 'package:voice_notes/core/packages/app_router/routes.dart';
import 'package:voice_notes/feature/presentation/pages/folders/screens/folders_screen.dart';
import 'package:voice_notes/feature/presentation/pages/notes/screens/folder_detail_screen.dart';
import 'package:voice_notes/feature/presentation/pages/notes/screens/note_detail_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/screens/settings_screen.dart';

///  AppRouter - класс для управления навигацией в приложении
///  [createRouter] - метод для создания экземпляра GoRouter
class AppRouter {
  /// {@macro app_router}
  const AppRouter();

  /// Ключ для доступа к корневому навигатору приложения
  static final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Начальный роут приложения
  static const String initialLocation = AppRoutes.folders;

  /// Метод для создания экземпляра GoRouter
  static GoRouter createRouter({NavigatorObserver? observer}) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      debugLogDiagnostics: true,
      observers: observer != null ? [observer] : null,
      routes: [
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state, navigationShell) =>
              RootScreen(navigationShell: navigationShell),
          branches: [
            // Branch 0: Folders
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.folders,
                  builder: (context, state) => const FoldersScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final folderId = state.pathParameters['id']!;

                        return FolderDetailScreen(folderId: folderId);
                      },
                      routes: [
                        GoRoute(
                          path: 'note/:noteId',
                          builder: (context, state) {
                            final folderId = state.pathParameters['id']!;
                            final noteId = state.pathParameters['noteId']!;

                            return NoteDetailScreen(
                              folderId: folderId,
                              noteId: noteId,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
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
  }
}
