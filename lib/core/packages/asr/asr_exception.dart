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
