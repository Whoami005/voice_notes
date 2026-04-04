import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:voice_notes/core/packages/asr/asr_config.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_isolate_runner.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Реализация ASR сервиса на базе sherpa-onnx
///
/// Сервис для распознавания речи.
/// Поддерживает Whisper (offline) и Transducer (offline + streaming) модели.
///
/// Вся тяжёлая работа (инициализация модели, транскрибация) выполняется
/// в фоновом изоляте для предотвращения блокировки UI.
/// Streaming API остаётся на main isolate для минимальной задержки.
@Singleton(as: AsrService)
class SherpaAsrService implements AsrService {
  // ==================== Состояние ====================

  bool _bindingsInitialized = false;
  AsrModelEntity? _currentModel;
  String? _currentModelPath;

  // Isolate runner для офлайн транскрибации (файлы и буферы)
  AsrIsolateRunner? _isolateRunner;

  // Streaming (Online) recognizer - lazy init при первом startStreaming()
  sherpa.OnlineRecognizer? _onlineRecognizer;
  sherpa.OnlineStream? _onlineStream;
  bool _isStreaming = false;
  String _streamingPartialText = '';

  // Stream controller для streaming результатов
  final _streamingResultsController =
      StreamController<AsrStreamingResult>.broadcast();

  // ==================== Getters ====================

  @override
  bool get isInitialized => _isolateRunner?.isRunning ?? false;

  @override
  AsrModelEntity? get currentModel => _currentModel;

  @override
  bool get isStreaming => _isStreaming;

  @override
  String get streamingPartialResult => _streamingPartialText;

  @override
  Stream<AsrStreamingResult> get streamingResults =>
      _streamingResultsController.stream;

  // ==================== Lifecycle ====================

  @override
  Future<void> initialize(AsrModelEntity model, String modelPath) async {
    // Запускаем изолят для офлайн транскрибации
    // Worker сам инициализирует bindings и создаёт recognizer в своём изоляте
    _isolateRunner = await AsrIsolateRunner.spawn();
    await _isolateRunner!.initialize(model, modelPath);

    // Сохраняем для lazy init streaming recognizer
    _currentModel = model;
    _currentModelPath = modelPath;
  }

  @override
  Future<void> switchModel(AsrModelEntity newModel, String newModelPath) async {
    // Останавливаем streaming если активен
    if (_isStreaming) await cancelStreaming();

    // Освобождаем текущие ресурсы
    _freeRecognizers();
    await _isolateRunner?.close();

    // Инициализируем с новой моделью
    await initialize(newModel, newModelPath);
  }

  @override
  Future<void> dispose() async {
    if (_isStreaming) await cancelStreaming();

    _freeRecognizers();
    await _isolateRunner?.close();
    await _streamingResultsController.close();

    _isolateRunner = null;
    _currentModel = null;
    _currentModelPath = null;
  }

  void _freeRecognizers() {
    _onlineStream?.free();
    _onlineStream = null;

    _onlineRecognizer?.free();
    _onlineRecognizer = null;
  }

  // ==================== Offline API ====================

  @override
  Future<AsrResult> transcribeFile(String filePath) async {
    _ensureInitialized();

    final file = File(filePath);
    if (!file.existsSync()) {
      throw AsrInvalidAudioException('File not found: $filePath');
    }

    // Делегируем транскрибацию фоновому изоляту
    return _isolateRunner!.transcribeFile(filePath);
  }

  @override
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate) async {
    _ensureInitialized();

    if (samples.isEmpty) {
      throw const AsrInvalidAudioException('Audio samples are empty');
    }

    // Делегируем транскрибацию фоновому изоляту
    return _isolateRunner!.transcribeAudio(samples, sampleRate);
  }

  // ==================== Streaming API ====================

  @override
  Future<void> startStreaming() async {
    _ensureInitialized();

    // Lazy init online recognizer при первом использовании streaming
    if (_onlineRecognizer == null) {
      _initOnlineRecognizerIfNeeded();
    }

    if (_isStreaming) {
      throw const AsrStreamingAlreadyActiveException();
    }

    _onlineStream = _onlineRecognizer!.createStream();
    _isStreaming = true;
    _streamingPartialText = '';
  }

  @override
  void feedAudioChunk(Float32List samples, {int sampleRate = 16000}) {
    if (!_isStreaming || _onlineStream == null) {
      throw const AsrStreamingNotActiveException();
    }

    _onlineStream!.acceptWaveform(samples: samples, sampleRate: sampleRate);

    // Декодируем пока готово
    while (_onlineRecognizer!.isReady(_onlineStream!)) {
      _onlineRecognizer!.decode(_onlineStream!);
    }

    // Получаем промежуточный результат
    final result = _onlineRecognizer!.getResult(_onlineStream!);
    final isEndpoint = _onlineRecognizer!.isEndpoint(_onlineStream!);

    if (result.text != _streamingPartialText) {
      _streamingPartialText = result.text;

      _streamingResultsController.add(
        AsrStreamingResult(
          partialText: _streamingPartialText,
          isEndpoint: isEndpoint,
        ),
      );
    }

    // Сбрасываем stream при достижении endpoint
    if (isEndpoint) {
      _onlineRecognizer!.reset(_onlineStream!);
    }
  }

  @override
  Future<AsrResult> stopStreaming() async {
    if (!_isStreaming || _onlineStream == null) {
      throw const AsrStreamingNotActiveException();
    }

    // Финализируем декодирование
    // Добавляем input finished сигнал
    _onlineStream!.inputFinished();

    while (_onlineRecognizer!.isReady(_onlineStream!)) {
      _onlineRecognizer!.decode(_onlineStream!);
    }

    final result = _onlineRecognizer!.getResult(_onlineStream!);
    final finalText = result.text.trim();

    // Очищаем состояние
    _onlineStream!.free();
    _onlineStream = null;
    _isStreaming = false;
    _streamingPartialText = '';

    return AsrResult(
      text: finalText,
      tokens: result.tokens,
      timestamps: result.timestamps,
    );
  }

  @override
  Future<void> cancelStreaming() async {
    if (!_isStreaming) return;

    _onlineStream?.free();
    _onlineStream = null;
    _isStreaming = false;
    _streamingPartialText = '';
  }

  // ==================== Private методы ====================

  void _ensureInitialized() {
    if (!isInitialized) throw const AsrNotInitializedException();
  }

  /// Инициализирует sherpa bindings на main isolate (lazy).
  ///
  /// Нужно только для streaming recognizer на main isolate.
  /// Worker isolate инициализирует свои bindings самостоятельно.
  void _initBindingsIfNeeded() {
    if (!_bindingsInitialized) {
      sherpa.initBindings();
      _bindingsInitialized = true;
    }
  }

  /// Lazy инициализация online recognizer для streaming.
  ///
  /// Вызывается при первом startStreaming(), чтобы избежать
  /// блокировки UI при initialize() если streaming не нужен.
  void _initOnlineRecognizerIfNeeded() {
    if (_currentModel == null || _currentModelPath == null) {
      throw const AsrNotInitializedException();
    }

    final config = _createConfig(_currentModel!, _currentModelPath!);

    // Только Transducer модели поддерживают streaming
    if (config is! TransducerAsrConfig) {
      throw const AsrStreamingNotSupportedException();
    }

    _initBindingsIfNeeded();
    _onlineRecognizer = _createOnlineRecognizer(config);
  }

  /// Создать конфигурацию на основе модели
  AsrModelConfig _createConfig(AsrModelEntity model, String modelPath) {
    final fileNames = model.getModelFileNames();

    return switch (model.modelType) {
      AsrModelType.whisper => WhisperAsrConfig(
        encoderPath: '$modelPath/${fileNames['encoder']}',
        decoderPath: '$modelPath/${fileNames['decoder']}',
        tokensPath: '$modelPath/${fileNames['tokens']}',
      ),
      AsrModelType.parakeetTdt => TransducerAsrConfig(
        encoderPath: '$modelPath/${fileNames['encoder']}',
        decoderPath: '$modelPath/${fileNames['decoder']}',
        joinerPath: '$modelPath/${fileNames['joiner']}',
        tokensPath: '$modelPath/${fileNames['tokens']}',
      ),
    };
  }

  /// Создать online (streaming) recognizer для Transducer модели
  sherpa.OnlineRecognizer _createOnlineRecognizer(TransducerAsrConfig config) {
    final sherpaConfig = sherpa.OnlineRecognizerConfig(
      model: sherpa.OnlineModelConfig(
        transducer: sherpa.OnlineTransducerModelConfig(
          encoder: config.encoderPath,
          decoder: config.decoderPath,
          joiner: config.joinerPath,
        ),
        tokens: config.tokensPath,
        numThreads: config.numThreads,
      ),
    );

    try {
      return sherpa.OnlineRecognizer(sherpaConfig);
    } catch (e) {
      throw AsrProcessingException('Failed to create online recognizer: $e', e);
    }
  }
}
