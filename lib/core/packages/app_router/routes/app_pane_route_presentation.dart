import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

abstract interface class AppPaneRoutePresentation {
  bool get isWorkspaceActive;

  bool get showAutomaticBack;

  String? get localBackLocation;
}

extension AppPaneRoutePresentationUi on AppPaneRoutePresentation {
  bool get automaticallyImplyLeading =>
      localBackLocation == null && showAutomaticBack;

  Color backgroundColor(BuildContext context) {
    final themeColors = context.themeColors;

    return isWorkspaceActive
        ? themeColors.workspacePane
        : themeColors.bgPrimary;
  }

  Widget? buildLeading(BuildContext context) {
    final backLocation = localBackLocation;

    return backLocation == null
        ? null
        : BackButton(onPressed: () => context.go(backLocation));
  }
}
