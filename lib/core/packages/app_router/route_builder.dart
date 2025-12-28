import 'package:flutter/material.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';

/// Wraps a widget with its [AppRouteWrapper.wrappedRoute] if implemented.
///
/// Use this in GoRoute builders to automatically apply wrappers:
/// ```dart
/// GoRoute(
///   path: '/folders',
///   builder: (context, state) => wrapRoute(context, const FoldersScreen()),
/// )
/// ```
Widget wrapRoute(BuildContext context, Widget child) {
  if (child is AppRouteWrapper) {
    return (child as AppRouteWrapper).wrappedRoute(context);
  }

  return child;
}
