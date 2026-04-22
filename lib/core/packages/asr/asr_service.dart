import 'dart:typed_data';

import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Абстрактный интерфейс сервиса распознавания речи.
///
/// Поддерживает два режима:
/// - **Offline**: транскрибация завершённых файлов или буферов.
/// - **Streaming**: real-time транскрибация потока аудио.
abstract interface class AsrService {
  bool get isInitialized;

  /// Broadcast-стрим готовности сервиса. Дедуплицирован — эмит только на
  /// реальных переходах. Новые подписчики читают текущее значение через
  /// [isInitialized].
  Stream<bool> get stateStream;

  AsrModelEntity? get currentModel;

  // Live-mic streaming API — временно отключено, не реализовано в worker'е.
  // Оставлено как reserved surface на случай возврата функциональности.
  // bool get isStreaming;

  /// Выбрасывает:
  /// - [AsrModelNotFoundException] если файлы модели не найдены
  /// - [AsrProcessingException] при ошибке инициализации
  Future<void> initialize(AsrModelEntity model, String modelPath);

  Future<void> switchModel(AsrModelEntity newModel, String newModelPath);

  /// Освобождает текущую модель и связанные ресурсы, оставив сервис живым.
  ///
  /// [stateStream] продолжает работать — его scope привязан к жизни сервиса,
  /// а не модели. Если до вызова сервис был готов, подписчики [stateStream]
  /// получат `false`.
  ///
  /// Используется, когда пользователь снял выбор модели. При смене модели
  /// вызывается [switchModel], который сам делает unload внутри.
  Future<void> unloadModel();

  /// Полная остановка: [unloadModel] + закрытие broadcast-стримов. После
  /// `dispose` сервис не пригоден к повторному использованию. Вызывается
  /// только при выходе из приложения и в тестах.
  Future<void> dispose();

  /// [filePath] — путь к WAV файлу (16kHz, mono).
  ///
  /// [onProgress] вызывается по мере обработки аудио. Для interactive-
  /// стратегий (streaming/chunked/chunked+vad) прогресс идёт по мере
  /// обработки, для `singlePass` — не приходит.
  ///
  /// [cancelToken] — кооперативная отмена. Для interactive-стратегий
  /// `cancel()` прерывает задачу между чанками/сегментами, `Future`
  /// завершается [AsrCancelledException]. Для `singlePass` отмена не
  /// прерывает in-flight FFI-decode — применяется на уровне очереди
  /// после завершения задачи.
  ///
  /// [strategyOverride] позволяет принудительно выбрать execution-формат
  /// вместо auto-планировщика.
  ///
  /// [audioDurationHint] помогает сервису построить детерминированный
  /// план без дополнительного чтения WAV-заголовка.
  ///
  /// Выбрасывает:
  /// - [AsrNotInitializedException] если сервис не инициализирован
  /// - [AsrInvalidAudioException] при неверном формате аудио
  /// - [AsrProcessingException] при ошибке распознавания
  /// - [AsrWorkerBusyException] если воркер занят другой задачей
  /// - [AsrCancelledException] при отмене через [cancelToken] (streaming only)
  Future<AsrResult> transcribeFile(
    String filePath, {
    void Function(AsrTranscribeProgress progress)? onProgress,
    AsrCancelToken? cancelToken,
    AsrTranscriptionStrategy strategyOverride = AsrTranscriptionStrategy.auto,
    Duration? audioDurationHint,
  });

  /// [samples] — PCM аудио в формате Float32 (-1.0 to 1.0).
  ///
  /// Выбрасывает:
  /// - [AsrNotInitializedException] если сервис не инициализирован
  /// - [AsrInvalidAudioException] при пустых данных
  /// - [AsrProcessingException] при ошибке распознавания
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate);

  // Live-mic streaming API — временно отключено, не реализовано в worker'е.
  // Оставлено как reserved surface на случай возврата функциональности.
  //
  // /// Выбрасывает:
  // /// - [AsrNotInitializedException] если сервис не инициализирован
  // /// - [AsrStreamingNotSupportedException] если модель не поддерживает
  // ///   streaming
  // /// - [AsrStreamingAlreadyActiveException] если сессия уже активна
  // /// - [AsrStreamingBusyException] если активна file-streaming задача
  // Future<void> startStreaming();
  //
  // /// [samples] — PCM аудио в формате Float32 (-1.0 to 1.0).
  // ///
  // /// Выбрасывает [AsrStreamingNotActiveException] если сессия не активна.
  // void feedAudioChunk(Float32List samples, {int sampleRate = 16000});
  //
  // /// Возвращает пустую строку если нет активной сессии.
  // String get streamingPartialResult;
  //
  // Stream<AsrStreamingResult> get streamingResults;
  //
  // /// Выбрасывает [AsrStreamingNotActiveException] если сессия не активна.
  // Future<AsrResult> stopStreaming();
  //
  // Future<void> cancelStreaming();
}
