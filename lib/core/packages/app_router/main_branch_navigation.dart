import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/main_shell.dart';

enum AppMainBranch {
  folders('/folders', branchIndex: 0),
  settings('/settings/general', branchIndex: 1);

  final String location;
  final int branchIndex;

  const AppMainBranch(this.location, {required this.branchIndex});

  static AppMainBranch fromIndex(int index) => switch (index) {
    0 => AppMainBranch.folders,
    1 => AppMainBranch.settings,
    _ => throw ArgumentError.value(index, 'index', 'Unknown main branch'),
  };
}

extension AppMainBranchNavigationContext on BuildContext {
  void goMainBranch(AppMainBranch branch) {
    final mainNavigation = MainNavigationScope.maybeOf(this);

    if (mainNavigation != null) {
      final isCurrentBranch =
          AppMainBranch.fromIndex(mainNavigation.currentIndex) == branch;

      mainNavigation.goBranch(
        branch.branchIndex,
        initialLocation: isCurrentBranch,
      );
      return;
    }

    go(branch.location);
  }
}
