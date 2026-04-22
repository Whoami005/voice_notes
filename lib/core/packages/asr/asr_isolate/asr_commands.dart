import 'dart:typed_data';

import 'package:voice_notes/core/packages/asr/asr_model_files.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_plan.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
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
/// Worker создаёт собственный recognizer с указанной моделью.
/// Модель загружается один раз и переиспользуется для всех транскрибаций.
final class InitializeCommand extends AsrCommand {
  /// Тип модели (whisper / transducer) для выбора recognizer'а.
  final AsrModelType modelType;

  /// Путь к директории с файлами модели.
  final String modelPath;

  /// Имена файлов модели (типизированные по варианту).
  final AsrModelFiles files;

  /// sherpa-onnx `modelType` для transducer-веток (`'nemo_transducer'`,
  /// пустая строка для стандартного Zipformer). Игнорируется для whisper.
  final String? sherpaModelType;

  const InitializeCommand({
    required this.modelType,
    required this.modelPath,
    required this.files,
    this.sherpaModelType,
  });
}

/// Транскрибация аудио файла.
///
/// Worker читает WAV файл, декодирует его и возвращает текст.
final class TranscribeCommand extends AsrCommand {
  /// ID запроса для сопоставления с ответом.
  final int requestId;

  /// Путь к WAV файлу для транскрибации.
  final String filePath;

  /// Конкретный execution-план для этого decode.
  final AsrTranscriptionPlan transcriptionPlan;

  const TranscribeCommand({
    required this.requestId,
    required this.filePath,
    this.transcriptionPlan = const AsrTranscriptionPlan.streaming(),
  });
}

/// Транскрибация аудио буфера.
///
/// Worker декодирует переданные PCM сэмплы и возвращает текст.
/// Используется для транскрибации без создания временного файла.
final class TranscribeAudioCommand extends AsrCommand {
  /// ID запроса для сопоставления с ответом.
  final int requestId;

  /// PCM аудио данные в формате Float32 (-1.0 to 1.0). Передаётся через
  /// isolate port как есть — `TypedData` не копируется в boxed `List<double>`.
  final Float32List samples;

  /// Частота дискретизации (обычно 16000 Hz).
  final int sampleRate;

  const TranscribeAudioCommand({
    required this.requestId,
    required this.samples,
    required this.sampleRate,
  });
}

/// Отмена уже идущей [TranscribeCommand]-задачи.
///
/// Обрабатывается только движком, поддерживающим cancellation — между чанками
/// декода воркер проверяет флаг и завершает задачу через
/// [TranscribeCancelledResponse]. Для offline-движков команда логируется и
/// игнорируется (прервать `decode()` невозможно без перезапуска изолята).
final class CancelTranscribeCommand extends AsrCommand {
  /// ID запроса, который нужно отменить.
  final int requestId;

  const CancelTranscribeCommand(this.requestId);
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
/// Ответы отправляются из worker isolate обратно в main после
/// выполнения команд.
sealed class AsrResponse {
  const AsrResponse();
}

/// Результат инициализации модели. Sealed — два исхода.
sealed class InitializeResponse extends AsrResponse {
  const InitializeResponse();
}

/// Модель успешно загружена.
final class InitializeOkResponse extends InitializeResponse {
  const InitializeOkResponse();
}

/// Загрузка модели провалилась.
final class InitializeFailedResponse extends InitializeResponse {
  final String error;

  const InitializeFailedResponse(this.error);
}

/// Промежуточное событие прогресса interactive-транскрибации.
///
/// Non-terminal ответ: worker эмитит N таких сообщений по ходу decode-loop'а
/// перед финальным [TranscribeResponse]. Для `singlePass` не отправляется.
final class TranscribeProgressResponse extends AsrResponse {
  /// ID запроса.
  final int requestId;

  /// Доля обработанного аудио, `0.0..1.0`.
  final double progress;

  /// Накопленный partial-text.
  final String partialText;

  /// Сколько секунд аудио уже обработано.
  final double processedSeconds;

  /// Полная длительность аудио в секундах.
  final double totalSeconds;

  /// Какая стратегия сейчас используется в worker'е.
  final AsrTranscriptionStrategy strategy;

  /// Текущий этап пайплайна.
  final AsrTranscribeStage stage;

  /// Сколько processing-units завершено.
  final int processedUnits;

  /// Полное число processing-units.
  final int totalUnits;

  const TranscribeProgressResponse({
    required this.requestId,
    required this.progress,
    required this.partialText,
    required this.processedSeconds,
    required this.totalSeconds,
    this.strategy = AsrTranscriptionStrategy.streaming,
    this.stage = AsrTranscribeStage.decoding,
    this.processedUnits = 0,
    this.totalUnits = 0,
  });
}

/// Терминальный ответ транскрибации. Sealed — четыре исхода:
/// - [TranscribeOkResponse] — успешно декодировано.
/// - [TranscribeCancelledResponse] — отменено через [CancelTranscribeCommand].
/// - [TranscribeBusyResponse] — воркер занят другой in-flight задачей.
/// - [TranscribeFailedResponse] — прочие ошибки.
sealed class TranscribeResponse extends AsrResponse {
  /// ID запроса для сопоставления с командой.
  final int requestId;

  const TranscribeResponse(this.requestId);
}

/// Успешная транскрибация.
final class TranscribeOkResponse extends TranscribeResponse {
  final AsrResult result;

  const TranscribeOkResponse(super.requestId, this.result);
}

/// Ошибка декодирования (не busy, не cancelled).
final class TranscribeFailedResponse extends TranscribeResponse {
  final String error;

  const TranscribeFailedResponse(super.requestId, this.error);
}

/// Задача отменена пользователем через [CancelTranscribeCommand].
final class TranscribeCancelledResponse extends TranscribeResponse {
  const TranscribeCancelledResponse(super.requestId);
}

/// Воркер занят другой in-flight задачей — конкретный типизированный
/// ответ вместо sentinel-строки в `error`.
final class TranscribeBusyResponse extends TranscribeResponse {
  const TranscribeBusyResponse(super.requestId);
}
