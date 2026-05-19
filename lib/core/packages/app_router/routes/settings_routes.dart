import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_restoration_ids.dart';
import 'package:voice_notes/core/packages/app_router/app_router.dart';
import 'package:voice_notes/core/packages/app_router/route_builder.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_route_names.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/feature/presentation/pages/queue/screens/queue_management_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/screens/general_settings_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/screens/models_settings_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/screens/settings_shell_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/screens/folder_storage_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/screens/storage_screen.dart';

/// Route module для ветки Settings.
class SettingsRouteModule {
  const SettingsRouteModule._();

  /// Создаёт ветку навигации для Settings
  static StatefulShellBranch branch() => StatefulShellBranch(
    navigatorKey: AppRouter.settingsBranchNavigatorKey,
    restorationScopeId: AppRestorationIds.settingsBranch,
    initialLocation: AppRoutes.settings.general,
    routes: [_settingsShellRoute],
  );

  static final _settingsShellRoute = StatefulShellRoute(
    restorationScopeId: AppRestorationIds.settingsShell,
    builder: (context, state, navigationShell) => navigationShell,
    navigatorContainerBuilder: (context, navigationShell, children) =>
        wrapRoute(
          context,
          SettingsShellScreen(
            navigationShell: navigationShell,
            children: children,
          ),
        ),
    branches: [
      StatefulShellBranch(
        preload: true,
        routes: [
          GoRoute(
            name: AppRouteNames.settings.general,
            path: AppRoutes.settings.general,
            pageBuilder: (context, state) =>
                _page(state, const GeneralSettingsScreen()),
            routes: [
              _storageRoute,
              GoRoute(
                name: AppRouteNames.settings.queue,
                path: 'queue',
                pageBuilder: (context, state) => _page(
                  state,
                  wrapRoute(context, const QueueManagementScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        preload: true,
        routes: [
          GoRoute(
            name: AppRouteNames.settings.models,
            path: AppRoutes.settings.models,
            pageBuilder: (context, state) =>
                _page(state, const ModelsSettingsScreen()),
          ),
        ],
      ),
    ],
  );

  static GoRoute get _storageRoute => GoRoute(
    name: AppRouteNames.settings.storage,
    path: 'storage',
    pageBuilder: (context, state) =>
        _page(state, wrapRoute(context, const StorageScreen())),
    routes: [
      GoRoute(
        name: AppRouteNames.settings.storageDetail,
        path: ':folderUid',
        pageBuilder: (context, state) => _page(
          state,
          wrapRoute(
            context,
            FolderStorageScreen(folderUid: _getFolderUid(state)),
          ),
        ),
      ),
    ],
  );

  static String? _getFolderUid(GoRouterState state) {
    final raw = state.pathParameters['folderUid'];
    // Это группа «без папки».
    final isNone = raw == null || raw.trim().isEmpty || raw.contains('none');

    return isNone ? null : raw;
  }

  static Page<void> _page(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      restorationId: AppRestorationIds.page(
        state.uri.path.replaceAll('/', '_'),
      ),
      child: child,
    );
  }
}
