import 'dart:typed_data';

import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
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

  bool get isStreaming;

  /// Выбрасывает:
  /// - [AsrModelNotFoundException] если файлы модели не найдены
  /// - [AsrProcessingException] при ошибке инициализации
  Future<void> initialize(AsrModelEntity model, String modelPath);

  Future<void> switchModel(AsrModelEntity newModel, String newModelPath);

  /// Освобождает текущую модель и связанные ресурсы, оставив сервис живым.
  ///
  /// [stateStream] и [streamingResults] продолжают работать — их scope
  /// привязан к жизни сервиса, а не модели. Если до вызова сервис был готов,
  /// подписчики [stateStream] получат `false`.
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
  /// Выбрасывает:
  /// - [AsrNotInitializedException] если сервис не инициализирован
  /// - [AsrInvalidAudioException] при неверном формате аудио
  /// - [AsrProcessingException] при ошибке распознавания
  Future<AsrResult> transcribeFile(String filePath);

  /// [samples] — PCM аудио в формате Float32 (-1.0 to 1.0).
  ///
  /// Выбрасывает:
  /// - [AsrNotInitializedException] если сервис не инициализирован
  /// - [AsrInvalidAudioException] при пустых данных
  /// - [AsrProcessingException] при ошибке распознавания
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate);

  /// Выбрасывает:
  /// - [AsrNotInitializedException] если сервис не инициализирован
  /// - [AsrStreamingNotSupportedException] если модель не поддерживает
  ///   streaming
  /// - [AsrStreamingAlreadyActiveException] если сессия уже активна
  Future<void> startStreaming();

  /// [samples] — PCM аудио в формате Float32 (-1.0 to 1.0).
  ///
  /// Выбрасывает [AsrStreamingNotActiveException] если сессия не активна.
  void feedAudioChunk(Float32List samples, {int sampleRate = 16000});

  /// Возвращает пустую строку если нет активной сессии.
  String get streamingPartialResult;

  Stream<AsrStreamingResult> get streamingResults;

  /// Выбрасывает [AsrStreamingNotActiveException] если сессия не активна.
  Future<AsrResult> stopStreaming();

  Future<void> cancelStreaming();
}
