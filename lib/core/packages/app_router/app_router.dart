import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/app_router/app_restoration_ids.dart';
import 'package:voice_notes/core/packages/app_router/main_shell.dart';
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

  static final foldersBranchNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'foldersBranch',
  );

  static final settingsBranchNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'settingsBranch',
  );

  static final detailPaneNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'foldersDetailPane',
  );

  /// Экземпляр GoRouter
  late final GoRouter router = _createRouter();

  /// Метод для создания экземпляра GoRouter
  GoRouter _createRouter({NavigatorObserver? observer}) {
    return GoRouter(
      restorationScopeId: AppRestorationIds.router,
      navigatorKey: rootNavigatorKey,
      initialLocation: AppRoutes.folders.root,
      debugLogDiagnostics: true,
      observers: observer != null ? [observer] : null,
      // Обработка ошибок навигации - редирект на корень ветки
      onException: (context, state, router) {
        final path = state.uri.path;

        router.go(
          path.startsWith(AppRoutes.settings.pattern)
              ? AppRoutes.settings.general
              : AppRoutes.folders.root,
        );
      },
      // Редирект для невалидных путей
      redirect: (context, state) {
        final path = state.uri.path;

        if (path == AppRoutes.settings.root) return AppRoutes.settings.general;

        // Проверка параметров для folder detail
        if (path.startsWith(AppRoutes.folders.pattern) &&
            path != AppRoutes.folders.root) {
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
          restorationScopeId: AppRestorationIds.rootShell,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [FoldersRouteModule.branch(), SettingsRouteModule.branch()],
        ),
      ],
    );
  }
}
