import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';
import 'package:voice_notes/core/packages/asr/asr_config.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_isolate_runner.dart';
import 'package:voice_notes/core/packages/asr/asr_model_files.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Реализация ASR на базе sherpa-onnx. Поддерживает Whisper (offline) и
/// Transducer (offline + streaming).
///
/// Инициализация модели и offline-транскрибация выполняются в фоновом
/// изоляте, чтобы не блокировать UI. Streaming остаётся на main isolate
/// для минимальной задержки.
@Singleton(as: AsrService)
class SherpaAsrService implements AsrService {
  bool _bindingsInitialized = false;
  AsrModelEntity? _currentModel;
  String? _currentModelPath;

  AsrIsolateRunner? _isolateRunner;

  // Lazy init при первом startStreaming(), чтобы не грузить streaming-модель
  // если streaming не используется.
  sherpa.OnlineRecognizer? _onlineRecognizer;
  sherpa.OnlineStream? _onlineStream;
  bool _isStreaming = false;
  String _streamingPartialText = '';

  // File-streaming flag: true пока идёт file-based streaming транскрибация
  // через воркер. Live-mic streaming (`startStreaming()`) блокируется в этот
  // момент, чтобы не поднимать второй OnlineRecognizer на ту же модель.
  bool _fileStreamingActive = false;

  final _streamingResultsController =
      StreamController<AsrStreamingResult>.broadcast();

  // Дедуп по [_lastReadyEmit], чтобы не будить drain без реальной смены.
  final _stateController = StreamController<bool>.broadcast();
  bool _lastReadyEmit = false;

  @override
  bool get isInitialized => _isolateRunner?.isRunning ?? false;

  @override
  Stream<bool> get stateStream => _stateController.stream;

  @override
  AsrModelEntity? get currentModel => _currentModel;

  @override
  bool get isStreaming => _isStreaming;

  @override
  String get streamingPartialResult => _streamingPartialText;

  @override
  Stream<AsrStreamingResult> get streamingResults =>
      _streamingResultsController.stream;

  void _emitReadyState() {
    final current = isInitialized;
    if (current == _lastReadyEmit) return;

    _lastReadyEmit = current;
    if (!_stateController.isClosed) _stateController.add(current);
  }

  @override
  Future<void> initialize(AsrModelEntity model, String modelPath) async {
    // Worker сам инициализирует bindings и создаёт recognizer в своём изоляте.
    _isolateRunner = await AsrIsolateRunner.spawn();
    await _isolateRunner!.initialize(model, modelPath);

    // Сохраняем для lazy init streaming recognizer.
    _currentModel = model;
    _currentModelPath = modelPath;

    _emitReadyState();
  }

  @override
  Future<void> switchModel(AsrModelEntity newModel, String newModelPath) async {
    await unloadModel();
    await initialize(newModel, newModelPath);
  }

  @override
  Future<void> unloadModel() async {
    if (_isStreaming) await cancelStreaming();

    _freeRecognizers();
    await _isolateRunner?.close();
    _isolateRunner = null;

    _currentModel = null;
    _currentModelPath = null;

    _emitReadyState();
  }

  @override
  Future<void> dispose() async {
    await unloadModel();

    // Broadcast-контроллеры живут пока жив сервис; закрываем их только
    // здесь, в true-teardown. Финальный `false` перед close не гарантирует
    // доставку подписчикам — полагаемся на onDone как сигнал остановки.
    await _streamingResultsController.close();
    if (!_stateController.isClosed) await _stateController.close();
  }

  void _freeRecognizers() {
    _onlineStream?.free();
    _onlineStream = null;

    _onlineRecognizer?.free();
    _onlineRecognizer = null;
  }

  @override
  Future<AsrResult> transcribeFile(
    String filePath, {
    void Function(AsrTranscribeProgress progress)? onProgress,
    AsrCancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    final file = File(filePath);
    if (!file.existsSync()) {
      throw AsrInvalidAudioException('File not found: $filePath');
    }

    _fileStreamingActive = _currentModel?.supportsStreaming ?? false;
    try {
      return await _isolateRunner!.transcribeFile(
        filePath,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
    } finally {
      _fileStreamingActive = false;
    }
  }

  @override
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate) async {
    _ensureInitialized();

    if (samples.isEmpty) {
      throw const AsrInvalidAudioException('Audio samples are empty');
    }

    return _isolateRunner!.transcribeAudio(samples, sampleRate);
  }

  @override
  Future<void> startStreaming() async {
    _ensureInitialized();
    assertStreamingNotBusy(fileStreamingActive: _fileStreamingActive);

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

  /// Проверка контракта feature-gate: нельзя поднять live-mic streaming,
  /// если активна file-streaming задача (иначе две instance'ы
  /// `OnlineRecognizer` на одной модели ломают native state).
  ///
  /// Extracted как top-level-ish static чтобы был юнит-тестируемой
  /// без spawn isolate / FFI.
  @visibleForTesting
  static void assertStreamingNotBusy({required bool fileStreamingActive}) {
    if (fileStreamingActive) {
      throw const AsrStreamingBusyException();
    }
  }

  @override
  void feedAudioChunk(Float32List samples, {int sampleRate = 16000}) {
    if (!_isStreaming || _onlineStream == null) {
      throw const AsrStreamingNotActiveException();
    }

    _onlineStream!.acceptWaveform(samples: samples, sampleRate: sampleRate);

    while (_onlineRecognizer!.isReady(_onlineStream!)) {
      _onlineRecognizer!.decode(_onlineStream!);
    }

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

    if (isEndpoint) _onlineRecognizer!.reset(_onlineStream!);
  }

  @override
  Future<AsrResult> stopStreaming() async {
    if (!_isStreaming || _onlineStream == null) {
      throw const AsrStreamingNotActiveException();
    }

    _onlineStream!.inputFinished();

    while (_onlineRecognizer!.isReady(_onlineStream!)) {
      _onlineRecognizer!.decode(_onlineStream!);
    }

    final result = _onlineRecognizer!.getResult(_onlineStream!);
    final finalText = result.text.trim();

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

  void _ensureInitialized() {
    if (!isInitialized) throw const AsrNotInitializedException();
  }

  /// Инициализирует sherpa bindings на main isolate для streaming recognizer.
  /// Worker isolate инициализирует свои bindings самостоятельно.
  void _initBindingsIfNeeded() {
    if (!_bindingsInitialized) {
      sherpa.initBindings();
      _bindingsInitialized = true;
    }
  }

  /// Lazy-инициализация online recognizer. Вызывается при первом
  /// `startStreaming()`, чтобы не блокировать UI на `initialize()` когда
  /// streaming не нужен.
  void _initOnlineRecognizerIfNeeded() {
    if (_currentModel == null || _currentModelPath == null) {
      throw const AsrNotInitializedException();
    }

    final config = _createConfig(_currentModel!, _currentModelPath!);

    // Streaming поддерживают только Transducer-модели.
    if (config is! TransducerAsrConfig) {
      throw const AsrStreamingNotSupportedException();
    }

    _initBindingsIfNeeded();
    _onlineRecognizer = _createOnlineRecognizer(config);
  }

  AsrModelConfig _createConfig(AsrModelEntity model, String modelPath) {
    return switch (model.getModelFiles()) {
      WhisperModelFiles(:final encoder, :final decoder, :final tokens) =>
        WhisperAsrConfig(
          encoderPath: '$modelPath/$encoder',
          decoderPath: '$modelPath/$decoder',
          tokensPath: '$modelPath/$tokens',
        ),
      TransducerModelFiles(
        :final encoder,
        :final decoder,
        :final joiner,
        :final tokens,
      ) =>
        TransducerAsrConfig(
          encoderPath: '$modelPath/$encoder',
          decoderPath: '$modelPath/$decoder',
          joinerPath: '$modelPath/$joiner',
          tokensPath: '$modelPath/$tokens',
          // Пустая строка → sherpa автодетектит (Zipformer);
          // 'nemo_transducer' — для NeMo bundle'ов.
          modelType: model.sherpaModelType ?? '',
        ),
    };
  }

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
        modelType: config.modelType,
      ),
    );

    try {
      return sherpa.OnlineRecognizer(sherpaConfig);
    } catch (e) {
      throw AsrProcessingException('Failed to create online recognizer: $e', e);
    }
  }
}
