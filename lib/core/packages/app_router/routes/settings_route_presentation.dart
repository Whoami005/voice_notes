import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/adaptive/window/app_window_class.dart';
import 'package:voice_notes/core/adaptive/window/workspace_layout_policy.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_pane_route_presentation.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_route_names.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';

enum SettingsSidebarSelection { models, queue, storage }

enum SettingsPaneBranch { general, models }

final class SettingsRoutePresentation implements AppPaneRoutePresentation {
  @override
  final bool isWorkspaceActive;
  final SettingsSidebarSelection selectedSidebarItem;
  final SettingsPaneBranch paneBranch;
  final bool showFullscreenChild;
  @override
  final bool showAutomaticBack;
  @override
  final String? localBackLocation;

  const SettingsRoutePresentation._({
    required this.isWorkspaceActive,
    required this.selectedSidebarItem,
    required this.paneBranch,
    required this.showFullscreenChild,
    required this.showAutomaticBack,
    this.localBackLocation,
  });

  factory SettingsRoutePresentation.fromContext(BuildContext context) {
    final state = GoRouterState.of(context);

    return SettingsRoutePresentation.resolve(
      routeName: state.topRoute?.name ?? state.name,
      windowClass: context.windowClass,
    );
  }

  factory SettingsRoutePresentation.resolve({
    required String? routeName,
    required AppWindowClass windowClass,
  }) {
    const routeNames = AppRouteNames.settings;
    final isWorkspaceActive = WorkspaceLayoutPolicy.canUseWorkspace(
      windowClass,
    );
    final isQueueRoute = routeName == routeNames.queue;
    final isStorageRoute = routeName == routeNames.storage;
    final isStorageDetailRoute = routeName == routeNames.storageDetail;
    final showFullscreenChild =
        !isWorkspaceActive &&
        (isQueueRoute || isStorageRoute || isStorageDetailRoute);

    if (routeName == routeNames.models) {
      return SettingsRoutePresentation._(
        isWorkspaceActive: isWorkspaceActive,
        selectedSidebarItem: SettingsSidebarSelection.models,
        paneBranch: SettingsPaneBranch.models,
        showFullscreenChild: false,
        showAutomaticBack: false,
      );
    }

    if (isQueueRoute) {
      return SettingsRoutePresentation._(
        isWorkspaceActive: isWorkspaceActive,
        selectedSidebarItem: SettingsSidebarSelection.queue,
        paneBranch: SettingsPaneBranch.general,
        showFullscreenChild: showFullscreenChild,
        showAutomaticBack: showFullscreenChild,
      );
    }

    if (isStorageRoute) {
      return SettingsRoutePresentation._(
        isWorkspaceActive: isWorkspaceActive,
        selectedSidebarItem: SettingsSidebarSelection.storage,
        paneBranch: SettingsPaneBranch.general,
        showFullscreenChild: showFullscreenChild,
        showAutomaticBack: showFullscreenChild,
      );
    }

    if (isStorageDetailRoute) {
      return SettingsRoutePresentation._(
        isWorkspaceActive: isWorkspaceActive,
        selectedSidebarItem: SettingsSidebarSelection.storage,
        paneBranch: SettingsPaneBranch.general,
        showFullscreenChild: showFullscreenChild,
        showAutomaticBack: showFullscreenChild,
        localBackLocation: isWorkspaceActive
            ? AppRoutes.settings.storage
            : null,
      );
    }

    return SettingsRoutePresentation._(
      isWorkspaceActive: isWorkspaceActive,
      selectedSidebarItem: SettingsSidebarSelection.models,
      paneBranch: SettingsPaneBranch.models,
      showFullscreenChild: false,
      showAutomaticBack: false,
    );
  }

  int get paneBranchIndex => switch (paneBranch) {
    SettingsPaneBranch.general => 0,
    SettingsPaneBranch.models => 1,
  };
}
