import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/main_branch_navigation.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/state/async/async_state_widgets.dart';
import 'package:voice_notes/feature/presentation/pages/folders/components/folders_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/folders/components/folders_list_section.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/voice_record_button/voice_record_button.dart';
import 'package:voice_notes/feature/presentation/widgets/asr_status_banner.dart';
import 'package:voice_notes/feature/presentation/widgets/audio/global_playback_mini_player.dart';
import 'package:voice_notes/feature/presentation/widgets/base_preferred_app_bar.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_bottom_nav.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

class FoldersScreen extends StatelessWidget implements AppRouteWrapper {
  const FoldersScreen({super.key});

  /// Навигация на главный экран папок
  static void go(BuildContext context) {
    context.go(AppRoutes.folders.root);
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return this;
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStateScaffold<FoldersCubit, FoldersState>(
      appBar: const _LoadingAppBar(),
      onSuccess: (context, _) {
        return const Scaffold(
          floatingActionButton: VoiceRecordButton(),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlobalPlaybackMiniPlayer(),
              AppBottomNav(currentBranch: AppMainBranch.folders),
            ],
          ),
          body: FoldersContent(),
        );
      },
    );
  }
}

class FoldersContent extends StatelessWidget {
  final bool useWorkspaceStyle;

  const FoldersContent({super.key, this.useWorkspaceStyle = false});

  @override
  Widget build(BuildContext context) {
    return RefreshableWrapper<FoldersCubit>(
      child: CustomScrollView(
        slivers: [
          FoldersAppBar(useWorkspaceStyle: useWorkspaceStyle),
          const AsrStatusBanner.sliver(),
          FoldersListSection(useWorkspaceStyle: useWorkspaceStyle),
        ],
      ),
    );
  }
}

class _LoadingAppBar extends BasePreferredAppBar {
  const _LoadingAppBar({super.key});

  @override
  State<_LoadingAppBar> createState() => _LoadingHeaderState();
}

class _LoadingHeaderState extends State<_LoadingAppBar> {
  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return AppBar(
      title: Text(context.l10n.foldersTitle, style: textTheme.displayLarge),
    );
  }
}
