import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/adaptive/window/app_adaptive_policy.dart';
import 'package:voice_notes/core/adaptive/window/app_window_size_enum.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/widgets/audio/global_playback_mini_player.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_bottom_nav.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_navigation_rail.dart';

class RootScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RootScreen({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final windowSize = context.windowSize;
    final showBottomNavigation = AppAdaptivePolicy.useBottomNavigation(
      windowSize,
    );
    final showNavigationRail = AppAdaptivePolicy.useNavigationRail(windowSize);

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      body: showNavigationRail
          ? _RailShellLayout(navigationShell: navigationShell, onTap: _onTap)
          : navigationShell,
      bottomNavigationBar: showBottomNavigation
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GlobalPlaybackMiniPlayer(),
                AppBottomNav(
                  currentIndex: navigationShell.currentIndex,
                  onTap: _onTap,
                ),
              ],
            )
          : null,
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _RailShellLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const _RailShellLayout({required this.navigationShell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppNavigationRail(
          currentIndex: navigationShell.currentIndex,
          onTap: onTap,
        ),
        Expanded(child: _BranchHost(navigationShell: navigationShell)),
      ],
    );
  }
}

class _BranchHost extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _BranchHost({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Future stage: branch-specific pane slot for desktop-like flows.
              Expanded(child: navigationShell),
            ],
          ),
        ),
        const GlobalPlaybackMiniPlayer(),
      ],
    );
  }
}
