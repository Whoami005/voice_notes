/// Dependency Injection module.
///
/// Provides centralized dependency registration using injectable + get_it.
///
/// Usage:
/// ```dart
/// import 'package:voice_notes/core/packages/di/di.dart';
///
/// void main() async {
///   await configureDependencies();
///   runApp(MyApp());
/// }
/// ```
library;

export 'app_environment.dart';
export 'app_initialization_result.dart';
export 'injection.dart' show configureDependencies, getIt;
