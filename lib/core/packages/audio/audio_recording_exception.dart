/// Базовое исключение для операций записи аудио
sealed class AudioRecordingException implements Exception {
  final String message;
  final Object? cause;

  const AudioRecordingException(this.message, [this.cause]);

  @override
  String toString() {
    final causeStr = cause != null ? ' ($cause)' : '';
    return 'AudioRecordingException: $message$causeStr';
  }
}

/// Запись уже активна
class RecordingAlreadyActiveException extends AudioRecordingException {
  const RecordingAlreadyActiveException([
    super.message = 'Recording session is already active',
  ]);
}

/// Запись не активна
class RecordingNotActiveException extends AudioRecordingException {
  const RecordingNotActiveException([
    super.message = 'No active recording session',
  ]);
}

/// Доступ к микрофону запрещён
class MicrophonePermissionDeniedException extends AudioRecordingException {
  const MicrophonePermissionDeniedException([
    super.message = 'Microphone permission denied',
  ]);
}

/// Общая ошибка записи
class RecordingFailedException extends AudioRecordingException {
  const RecordingFailedException(super.message, [super.cause]);
}
