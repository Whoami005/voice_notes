import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_router.dart';
import 'package:voice_notes/core/packages/app_router/route_builder.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/screens/general_settings_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/screens/models_settings_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/screens/settings_shell_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/screens/folder_storage_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/screens/storage_screen.dart';

/// Route module для ветки Settings.
class SettingsRouteModule {
  const SettingsRouteModule._();

  /// Создаёт ветку навигации для Settings
  static StatefulShellBranch branch() =>
      StatefulShellBranch(routes: [_settingsShellRoute]);

  static final _settingsShellRoute = StatefulShellRoute(
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
            path: AppRoutes.settings.general,
            builder: (context, state) => const GeneralSettingsScreen(),
            routes: [_storageRoute],
          ),
        ],
      ),
      StatefulShellBranch(
        preload: true,
        routes: [
          GoRoute(
            path: AppRoutes.settings.models,
            builder: (context, state) => const ModelsSettingsScreen(),
          ),
        ],
      ),
    ],
  );

  static String? _getFolderUid(GoRouterState state) {
    final raw = state.pathParameters['folderUid'];

    // Empty string из URL — это группа «без папки».
    return (raw == null || raw.trim().isEmpty) ? null : raw;
  }

  static GoRoute get _storageRoute => GoRoute(
    path: 'storage',
    parentNavigatorKey: AppRouter.rootNavigatorKey,
    builder: (context, state) => wrapRoute(context, const StorageScreen()),
    routes: [
      GoRoute(
        path: ':folderUid',
        parentNavigatorKey: AppRouter.rootNavigatorKey,
        builder: (context, state) => wrapRoute(
          context,
          FolderStorageScreen(folderUid: _getFolderUid(state)),
        ),
      ),
    ],
  );
}
