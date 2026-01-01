import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

// ============================================================================
// Команды (main isolate → worker isolate)
// ============================================================================

/// Базовый класс команд для ASR изолята.
///
/// Команды отправляются из main isolate в worker для выполнения операций.
sealed class AsrCommand {
  const AsrCommand();
}

/// Инициализация модели в изоляте.
///
/// Worker создаёт собственный [OfflineRecognizer] с указанной моделью.
/// Модель загружается один раз и переиспользуется для всех транскрибаций.
final class InitializeCommand extends AsrCommand {
  /// Тип модели (whisper / parakeetTdt) для выбора конфигурации.
  final AsrModelType modelType;

  /// Путь к директории с файлами модели.
  final String modelPath;

  /// Имена файлов модели (encoder, decoder, tokens, joiner).
  final Map<String, String> fileNames;

  const InitializeCommand({
    required this.modelType,
    required this.modelPath,
    required this.fileNames,
  });
}

/// Транскрибация аудио файла.
///
/// Worker читает WAV файл, декодирует его и возвращает текст.
final class TranscribeCommand extends AsrCommand {
  /// Путь к WAV файлу для транскрибации.
  final String filePath;

  const TranscribeCommand({required this.filePath});
}

/// Завершение работы изолята.
///
/// Worker освобождает ресурсы recognizer'а и закрывает порт.
final class DisposeCommand extends AsrCommand {
  const DisposeCommand();
}

// ============================================================================
// Ответы (worker isolate → main isolate)
// ============================================================================

/// Базовый класс ответов от ASR изолята.
///
/// Ответы отправляются из worker isolate обратно в main после выполнения команд.
sealed class AsrResponse {
  const AsrResponse();
}

/// Результат инициализации модели.
final class InitializeResponse extends AsrResponse {
  /// Успешно ли загружена модель.
  final bool success;

  /// Текст ошибки, если инициализация не удалась.
  final String? error;

  const InitializeResponse({required this.success, this.error});

  const InitializeResponse.ok() : success = true, error = null;

  const InitializeResponse.failed(String message)
    : success = false,
      error = message;
}

/// Результат транскрибации.
final class TranscribeResponse extends AsrResponse {
  /// Результат транскрибации (текст, токены, время обработки).
  final AsrResult? result;

  /// Текст ошибки, если транскрибация не удалась.
  final String? error;

  const TranscribeResponse({this.result, this.error});

  const TranscribeResponse.ok(AsrResult this.result) : error = null;

  const TranscribeResponse.failed(String message)
    : result = null,
      error = message;
}
