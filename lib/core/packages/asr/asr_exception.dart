/// Базовое исключение для ASR операций
sealed class AsrException implements Exception {
  final String message;
  final Object? cause;

  const AsrException(this.message, [this.cause]);

  @override
  String toString() {
    final causeStr = cause != null ? ' ($cause)' : '';
    return 'AsrException: $message$causeStr';
  }
}

/// Сервис не инициализирован
class AsrNotInitializedException extends AsrException {
  const AsrNotInitializedException([
    super.message = 'ASR service not initialized',
  ]);
}

/// Модель не найдена или файлы отсутствуют
class AsrModelNotFoundException extends AsrException {
  const AsrModelNotFoundException(super.message);
}

/// Загруженная модель сменилась между планированием и стартом транскрибации.
class AsrModelChangedException extends AsrException {
  const AsrModelChangedException([
    super.message = 'ASR model changed before transcription started',
  ]);
}

/// Некорректный формат аудио
class AsrInvalidAudioException extends AsrException {
  const AsrInvalidAudioException(super.message);
}

/// Ошибка при распознавании
class AsrProcessingException extends AsrException {
  const AsrProcessingException(super.message, [super.cause]);
}

/// Streaming не поддерживается для данной модели (например, Whisper)
class AsrStreamingNotSupportedException extends AsrException {
  const AsrStreamingNotSupportedException([
    super.message = 'Streaming is not supported for this model',
  ]);
}

/// Streaming сессия уже активна
class AsrStreamingAlreadyActiveException extends AsrException {
  const AsrStreamingAlreadyActiveException([
    super.message = 'Streaming session is already active',
  ]);
}

/// Streaming сессия не активна
class AsrStreamingNotActiveException extends AsrException {
  const AsrStreamingNotActiveException([
    super.message = 'No active streaming session',
  ]);
}

/// Транскрибация отменена пользователем через [AsrCancelToken].
///
/// Для streaming-моделей — в любой момент между чанками. Для non-streaming
/// моделей этот тип исключения не бросается — отмена применяется на уровне
/// очереди после завершения FFI-decode.
class AsrCancelledException extends AsrException {
  const AsrCancelledException([super.message = 'Transcription cancelled']);
}

/// Воркер занят другой in-flight задачей.
///
/// Защита от параллельного запуска `TranscribeCommand`'ов на одном
/// `OnlineRecognizer`/`OfflineRecognizer`. В текущей очереди задачи обычно
/// идут последовательно; это защита на уровне протокола.
class AsrWorkerBusyException extends AsrProcessingException {
  const AsrWorkerBusyException([
    super.message = 'ASR worker is busy with another request',
  ]);
}

/// Попытка стартовать live-mic streaming при активной file-streaming задаче.
///
/// Feature-gate: live-mic и file-streaming используют один native recognizer;
/// параллельный запуск ломает его состояние.
class AsrStreamingBusyException extends AsrException {
  const AsrStreamingBusyException([
    super.message = 'Cannot start streaming: file-streaming is in progress',
  ]);
}
