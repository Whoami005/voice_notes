import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

/// Рендерит отдельную pane-оболочку workspace.
class AppWorkspacePane extends StatelessWidget {
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  const AppWorkspacePane({
    required this.child,
    super.key,
    this.footer,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: themeColors.workspacePane,
        borderRadius: BorderRadius.circular(AppSizes.workspacePaneRadius),
        border: Border.all(color: themeColors.workspaceBorderSoft),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.workspacePaneRadius),
        child: Column(
          children: [
            Expanded(
              child: Padding(padding: padding, child: child),
            ),
            if (footer case final footer?)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: themeColors.workspaceBorderSoft),
                  ),
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
