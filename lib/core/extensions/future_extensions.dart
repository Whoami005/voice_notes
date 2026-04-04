extension FutureMinDuration<T> on Future<T> {
  Future<T> atLeast([
    Duration duration = const Duration(milliseconds: 500),
  ]) async {
    final results = await Future.wait<dynamic>([
      this,
      Future.delayed(duration),
    ]);

    return results[0] as T;
  }
}
