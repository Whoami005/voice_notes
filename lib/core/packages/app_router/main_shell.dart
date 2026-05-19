import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';

/// Хостит активную ветку роутера и общий фон shell-уровня.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return MainNavigationScope(
      navigationShell: navigationShell,
      child: Scaffold(
        backgroundColor: themeColors.workspaceShell,
        body: navigationShell,
      ),
    );
  }
}

/// Даёт дочерним экранам доступ к переключению корневых веток.
class MainNavigationScope extends InheritedWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationScope({
    required this.navigationShell,
    required super.child,
    super.key,
  });

  static MainNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainNavigationScope>();
  }

  static MainNavigationScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'MainNavigationScope is not found in context');

    return scope!;
  }

  int get currentIndex => navigationShell.currentIndex;

  void goBranch(int index, {bool initialLocation = false}) {
    navigationShell.goBranch(index, initialLocation: initialLocation);
  }

  @override
  bool updateShouldNotify(covariant MainNavigationScope oldWidget) {
    return navigationShell.currentIndex !=
        oldWidget.navigationShell.currentIndex;
  }
}
