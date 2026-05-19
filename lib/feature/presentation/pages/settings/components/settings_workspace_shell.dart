import 'package:flutter/material.dart';
import 'package:voice_notes/core/packages/app_router/main_branch_navigation.dart';
import 'package:voice_notes/feature/presentation/pages/settings/components/settings_workspace_right_pane.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/screens/general_settings_screen.dart';
import 'package:voice_notes/feature/presentation/widgets/workspace/app_workspace_dock.dart';
import 'package:voice_notes/feature/presentation/widgets/workspace/app_workspace_shell.dart';

/// Собирает workspace-версию экрана настроек.
class SettingsWorkspaceShell extends StatelessWidget {
  final List<Widget> children;

  const SettingsWorkspaceShell({
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppWorkspaceShell(
      leftPane: const AppWorkspacePaneConfig(
        child: GeneralSettingsScreen(useWorkspaceStyle: true),
        footer: AppWorkspaceDock(currentBranch: AppMainBranch.settings),
      ),
      rightPane: AppWorkspacePaneConfig(
        child: SettingsWorkspaceRightPane(children: children),
      ),
    );
  }
}
