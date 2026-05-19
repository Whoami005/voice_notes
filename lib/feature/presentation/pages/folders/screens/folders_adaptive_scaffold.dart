import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/adaptive/adaptive.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/main_branch_navigation.dart';
import 'package:voice_notes/core/packages/app_router/routes/folders_route_presentation.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folders/screens/folders_screen.dart';
import 'package:voice_notes/feature/presentation/widgets/workspace/app_workspace_dock.dart';
import 'package:voice_notes/feature/presentation/widgets/workspace/app_workspace_shell.dart';

/// Перекладывает ветку folders в split-view, когда окно это позволяет.
class FoldersAdaptiveScaffold extends StatelessWidget
    implements AppRouteWrapper {
  final Widget child;

  const FoldersAdaptiveScaffold({required this.child, super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => FoldersCubit(repository: getIt<FolderRepository>()),
      child: this,
    );
  }

  @visibleForTesting
  static bool canUseWorkspaceLayout(BoxConstraints constraints) {
    return WorkspaceLayoutPolicy.canUseWorkspace(constraints.windowClass);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWorkspaceLayout = canUseWorkspaceLayout(constraints);

        if (!useWorkspaceLayout) return child;

        final presentation = FoldersRoutePresentation.fromContext(context);

        return AppWorkspaceShell(
          leftPane: const AppWorkspacePaneConfig(
            child: FoldersContent(useWorkspaceStyle: true),
            footer: AppWorkspaceDock(currentBranch: AppMainBranch.folders),
          ),
          rightPane: AppWorkspacePaneConfig(
            child: presentation.showDetailPane
                ? child
                : const _EmptyDetailPane(),
          ),
        );
      },
    );
  }
}

/// Показывает пустую правую панель, пока деталь не выбрана.
class _EmptyDetailPane extends StatelessWidget {
  const _EmptyDetailPane();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return ColoredBox(
      color: themeColors.bgPrimary,
      child: Center(
        child: Icon(
          Icons.folder_open_outlined,
          size: AppSizes.p64,
          color: themeColors.textTertiary,
        ),
      ),
    );
  }
}
