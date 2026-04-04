import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/app_router/root_screen.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/app_router/routes/folders_routes.dart';
import 'package:voice_notes/core/packages/app_router/routes/settings_routes.dart';

/// AppRouter - класс для управления навигацией в приложении.
///
/// Использует модульную структуру с [FoldersRouteModule] и
/// [SettingsRouteModule]
/// для организации роутов по веткам навигации.
@singleton
class AppRouter {
  /// Ключ для доступа к корневому навигатору приложения
  static final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Экземпляр GoRouter
  late final GoRouter router = _createRouter();

  /// Метод для создания экземпляра GoRouter
  GoRouter _createRouter({NavigatorObserver? observer}) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoutes.folders.root,
      debugLogDiagnostics: true,
      observers: observer != null ? [observer] : null,

      // Обработка ошибок навигации - редирект на корень ветки
      onException: (context, state, router) {
        final path = state.matchedLocation;
        final isSettings = path.startsWith('/settings');

        isSettings
            ? router.go(AppRoutes.settings.general)
            : router.go(AppRoutes.folders.root);
      },

      // Редирект для невалидных путей
      redirect: (context, state) {
        final path = state.matchedLocation;

        if (path == '/settings') return AppRoutes.settings.general;

        // Проверка параметров для folder detail
        if (path.startsWith('/folders/') && path != '/folders') {
          final segments = path.split('/');

          if (segments.length >= 3) {
            final folderId = segments[2];
            final isId = folderId.isEmpty || folderId == ':id';

            if (isId) return AppRoutes.folders.root;
          }
        }

        return null;
      },

      routes: [
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state, navigationShell) =>
              RootScreen(navigationShell: navigationShell),
          branches: [FoldersRouteModule.branch(), SettingsRouteModule.branch()],
        ),
      ],
    );
  }
}
