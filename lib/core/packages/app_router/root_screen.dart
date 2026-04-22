import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/widgets/audio/global_playback_mini_player.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_bottom_nav.dart';

class RootScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RootScreen({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GlobalPlaybackMiniPlayer(),
          AppBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
          ),
        ],
      ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
