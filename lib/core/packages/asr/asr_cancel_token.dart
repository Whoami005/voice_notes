// ignore_for_file: comment_references

import 'dart:async';

/// Кооперативный cancel-токен для долгих ASR-операций.
///
/// Передаётся в [AsrService.transcribeFile] и прокидывается вниз до воркера.
/// [cancel] идемпотентен; [whenCancelled] допускает множество независимых
/// подписчиков через `Future.then(...)`.
///
/// Для non-streaming моделей (Whisper) вызов [cancel] не прерывает уже идущий
/// FFI-decode — отмена применяется на уровне очереди после завершения задачи.
class AsrCancelToken {
  AsrCancelToken();

  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}
