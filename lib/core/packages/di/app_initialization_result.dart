sealed class AppInitializationResult {
  const AppInitializationResult();
}

final class AppInitializationSuccess extends AppInitializationResult {
  const AppInitializationSuccess();
}

final class AppInitializationFailure extends AppInitializationResult {
  final Object error;
  final StackTrace? stackTrace;

  const AppInitializationFailure({required this.error, this.stackTrace});
}
