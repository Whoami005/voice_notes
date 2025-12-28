import 'package:flutter/material.dart';

/// Interface for screens that need to be wrapped with providers.
///
/// Similar to AutoRouteWrapper from auto_route package.
/// Screens implementing this interface will have their [wrappedRoute]
/// called automatically by the router.
///
/// Example:
/// ```dart
/// class FoldersScreen extends StatefulWidget implements AppRouteWrapper {
///   const FoldersScreen({super.key});
///
///   @override
///   Widget wrappedRoute(BuildContext context) {
///     return BlocProvider(
///       create: (context) => FoldersCubit()..init(),
///       child: this,
///     );
///   }
///
///   @override
///   State<FoldersScreen> createState() => _FoldersScreenState();
/// }
/// ```
abstract interface class AppRouteWrapper {
  /// Wraps this widget with necessary providers or other wrappers.
  ///
  /// The implementation should return `this` as the child of the wrapper.
  Widget wrappedRoute(BuildContext context);
}
