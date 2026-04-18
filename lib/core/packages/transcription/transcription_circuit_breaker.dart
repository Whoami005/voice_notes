/// Circuit breaker для очереди транскрибации: считает подряд проваленные
/// попытки, при достижении порога выставляет [isPaused] в `true`.
/// Снимается через [reset] (при пользовательском `retry()` или ASR ready).
final class TranscriptionCircuitBreaker {
  TranscriptionCircuitBreaker({required int threshold})
    : _threshold = threshold;

  final int _threshold;
  int _consecutive = 0;
  bool _paused = false;

  bool get isPaused => _paused;

  void recordSuccess() {
    _consecutive = 0;
  }

  void recordFailure() {
    _consecutive++;
    if (_consecutive >= _threshold) _paused = true;
  }

  void reset() {
    _consecutive = 0;
    _paused = false;
  }
}
