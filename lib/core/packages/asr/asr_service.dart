import 'dart:typed_data';

import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Абстрактный интерфейс для сервиса распознавания речи (ASR)
///
/// Поддерживает два режима работы:
/// - **Offline**: транскрибация завершённых аудио файлов или данных
/// - **Streaming**: real-time транскрибация потока аудио
abstract interface class AsrService {
  // ==================== Состояние ====================

  /// Готов ли сервис к работе (инициализирован с моделью)
  bool get isInitialized;

  /// Broadcast-стрим готовности сервиса. Эмитит `true` когда модель
  /// проинициализирована и готова транскрибировать, `false` после dispose.
  /// Дедуплицирован: эмит происходит только на реальных переходах.
  /// Новые подписчики читают текущее состояние через [isInitialized].
  Stream<bool> get stateStream;

  /// Текущая загруженная модель
  AsrModelEntity? get currentModel;

  /// Активна ли streaming сессия
  bool get isStreaming;

  // ==================== Lifecycle ====================

  /// Инициализация сервиса с указанной моделью
  ///
  /// [model] - сущность модели для определения типа и конфигурации
  /// [modelPath] - путь к директории с файлами модели
  ///
  /// Выбрасывает:
  /// - [AsrModelNotFoundException] если файлы модели не найдены
  /// - [AsrProcessingException] при ошибке инициализации
  Future<void> initialize(AsrModelEntity model, String modelPath);

  /// Сменить модель (освобождает текущую и инициализирует новую)
  ///
  /// [newModel] - новая модель
  /// [newModelPath] - путь к директории новой модели
  Future<void> switchModel(AsrModelEntity newModel, String newModelPath);

  /// Освободить все ресурсы
  Future<void> dispose();

  // ==================== Offline API ====================

  /// Транскрибировать аудио файл
  ///
  /// [filePath] - путь к WAV файлу (16kHz, mono)
  ///
  /// Возвращает [AsrResult] с распознанным текстом
  ///
  /// Выбрасывает:
  /// - [AsrNotInitializedException] если сервис не инициализирован
  /// - [AsrInvalidAudioException] при неверном формате аудио
  /// - [AsrProcessingException] при ошибке распознавания
  Future<AsrResult> transcribeFile(String filePath);

  /// Транскрибировать аудио данные
  ///
  /// [samples] - PCM аудио данные в формате Float32 (-1.0 to 1.0)
  /// [sampleRate] - частота дискретизации (рекомендуется 16000)
  ///
  /// Возвращает [AsrResult] с распознанным текстом
  ///
  /// Выбрасывает:
  /// - [AsrNotInitializedException] если сервис не инициализирован
  /// - [AsrInvalidAudioException] при пустых данных
  /// - [AsrProcessingException] при ошибке распознавания
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate);

  // ==================== Streaming API ====================

  /// Начать streaming сессию
  ///
  /// Выбрасывает:
  /// - [AsrNotInitializedException] если сервис не инициализирован
  /// - [AsrStreamingNotSupportedException] если модель не поддерживает
  ///   streaming
  /// - [AsrStreamingAlreadyActiveException] если сессия уже активна
  Future<void> startStreaming();

  /// Отправить аудио чанк в streaming сессию
  ///
  /// [samples] - PCM аудио данные в формате Float32 (-1.0 to 1.0)
  /// [sampleRate] - частота дискретизации (рекомендуется 16000)
  ///
  /// Выбрасывает:
  /// - [AsrStreamingNotActiveException] если сессия не активна
  void feedAudioChunk(Float32List samples, {int sampleRate = 16000});

  /// Получить текущий промежуточный результат streaming
  ///
  /// Возвращает пустую строку если нет активной сессии
  String get streamingPartialResult;

  /// Stream промежуточных результатов для реактивного UI
  ///
  /// Эмитит [AsrStreamingResult] при каждом обновлении текста
  Stream<AsrStreamingResult> get streamingResults;

  /// Завершить streaming сессию и получить финальный результат
  ///
  /// Возвращает [AsrResult] с полным распознанным текстом
  ///
  /// Выбрасывает:
  /// - [AsrStreamingNotActiveException] если сессия не активна
  Future<AsrResult> stopStreaming();

  /// Отменить streaming сессию без получения результата
  Future<void> cancelStreaming();
}
