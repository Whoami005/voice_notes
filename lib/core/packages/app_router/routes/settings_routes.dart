import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/route_builder.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/screens/general_settings_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/screens/models_settings_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/screens/settings_shell_screen.dart';

/// Route module для ветки Settings.
///
/// Использует [StatefulShellRoute] с [navigatorContainerBuilder]
/// для поддержки свайпа между табами через [TabBarView].
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
}
