import 'package:flutter/material.dart';
import 'package:voice_notes/core/packages/app_router/routes/settings_route_presentation.dart';

/// Выбирает child для правой панели настроек.
class SettingsWorkspaceRightPane extends StatelessWidget {
  final List<Widget> children;

  const SettingsWorkspaceRightPane({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    final presentation = SettingsRoutePresentation.fromContext(context);

    return IndexedStack(
      index: presentation.paneBranchIndex,
      children: children,
    );
  }
}
