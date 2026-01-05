import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/route_builder.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/feature/presentation/pages/settings/screens/settings_screen.dart';

/// Route module для ветки Settings.
///
/// Содержит конфигурацию роутов для:
/// - /settings (экран настроек)
class SettingsRouteModule {
  const SettingsRouteModule._();

  /// Создаёт ветку навигации для Settings
  static StatefulShellBranch branch() =>
      StatefulShellBranch(routes: [_rootRoute]);

  static GoRoute get _rootRoute => GoRoute(
    path: AppRoutes.settings.pattern,
    builder: (context, state) => wrapRoute(context, const SettingsScreen()),
  );
}
