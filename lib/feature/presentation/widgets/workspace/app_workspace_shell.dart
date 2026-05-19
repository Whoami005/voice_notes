import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voice_notes/core/adaptive/window/app_window_size_enum.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/widgets/workspace/app_workspace_pane.dart';

/// Описывает содержимое одной workspace-панели.
final class AppWorkspacePaneConfig {
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  const AppWorkspacePaneConfig({
    required this.child,
    this.footer,
    this.padding = EdgeInsets.zero,
  });
}

/// Строит двухпанельный workspace-лейаут.
class AppWorkspaceShell extends StatelessWidget {
  final AppWorkspacePaneConfig leftPane;
  final AppWorkspacePaneConfig rightPane;

  const AppWorkspaceShell({
    required this.leftPane,
    required this.rightPane,
    super.key,
  });

  static const double horizontalPadding =
      AppSizes.workspaceHorizontalPadding * 2;
  static const double gap = AppSizes.workspacePaneGap;

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return SafeArea(
      bottom: false,
      child: ColoredBox(
        color: themeColors.workspaceShell,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : AppWindowSizeEnum.expanded.maxWidth;
            final double usableWidth = availableWidth > horizontalPadding + gap
                ? availableWidth - horizontalPadding - gap
                : 0;
            final leftWidth = _leftPaneWidth(usableWidth);
            final rightWidth = math.max<double>(
              AppSizes.workspaceRightPaneMinWidth,
              usableWidth - leftWidth,
            );

            return Padding(
              padding: const EdgeInsets.all(
                AppSizes.workspaceHorizontalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSizes.workspacePaneGap,
                children: [
                  SizedBox(
                    width: leftWidth,
                    child: AppWorkspacePane(
                      footer: leftPane.footer,
                      padding: leftPane.padding,
                      child: leftPane.child,
                    ),
                  ),
                  SizedBox(
                    width: rightWidth,
                    child: AppWorkspacePane(
                      footer: rightPane.footer,
                      padding: rightPane.padding,
                      child: rightPane.child,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _leftPaneWidth(double usableWidth) {
    final preferred = usableWidth * 0.36;

    return math.min(
      AppSizes.workspaceLeftPaneMaxWidth,
      math.max(AppSizes.workspaceLeftPaneMinWidth, preferred),
    );
  }
}
