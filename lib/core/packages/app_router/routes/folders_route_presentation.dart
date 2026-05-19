import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/adaptive/window/app_window_class.dart';
import 'package:voice_notes/core/adaptive/window/workspace_layout_policy.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_pane_route_presentation.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_route_names.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';

final class FoldersRoutePresentation implements AppPaneRoutePresentation {
  @override
  final bool isWorkspaceActive;
  final bool showDetailPane;
  @override
  final bool showAutomaticBack;
  @override
  final String? localBackLocation;

  const FoldersRoutePresentation._({
    required this.isWorkspaceActive,
    required this.showDetailPane,
    required this.showAutomaticBack,
    this.localBackLocation,
  });

  factory FoldersRoutePresentation.fromContext(BuildContext context) {
    final state = GoRouterState.of(context);

    return FoldersRoutePresentation.resolve(
      routeName: state.topRoute?.name ?? state.name,
      pathParameters: state.pathParameters,
      windowClass: context.windowClass,
    );
  }

  factory FoldersRoutePresentation.resolve({
    required String? routeName,
    required Map<String, String> pathParameters,
    required AppWindowClass windowClass,
  }) {
    const routeNames = AppRouteNames.folders;
    final isWorkspaceActive = WorkspaceLayoutPolicy.canUseWorkspace(
      windowClass,
    );

    if (!isWorkspaceActive) {
      return const FoldersRoutePresentation._(
        isWorkspaceActive: false,
        showDetailPane: false,
        showAutomaticBack: true,
      );
    }

    if (routeName == routeNames.detail) {
      return const FoldersRoutePresentation._(
        isWorkspaceActive: true,
        showDetailPane: true,
        showAutomaticBack: false,
      );
    }

    if (routeName == routeNames.noteDetail) {
      return FoldersRoutePresentation._(
        isWorkspaceActive: true,
        showDetailPane: true,
        showAutomaticBack: false,
        localBackLocation: AppRoutes.folders.detail(pathParameters['id']!),
      );
    }

    return const FoldersRoutePresentation._(
      isWorkspaceActive: true,
      showDetailPane: false,
      showAutomaticBack: false,
    );
  }
}
