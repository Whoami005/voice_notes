import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_commands.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_isolate_worker.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Управляет фоновым изолятом для офлайн ASR транскрибации.
///
/// Изолят создаётся при вызове [spawn] и живёт до [close].
/// Это позволяет избежать повторной загрузки модели (~500ms-2s)
/// при каждой транскрибации.
///
/// Использует паттерн RawReceivePort для разделения логики инициализации
/// и обработки сообщений. Поддерживает множественные одновременные запросы
/// через `Map<int, Completer>`.
///
/// Пример использования:
/// ```dart
/// final runner = await AsrIsolateRunner.spawn();
/// await runner.initialize(model, modelPath);
/// final result = await runner.transcribeFile(filePath);
/// await runner.close();
/// ```
class AsrIsolateRunner {
  final ReceivePort _responses;
  final SendPort _commands;

  /// Ожидающие ответа запросы: requestId -> Completer.
  final Map<int, Completer<AsrResult>> _pendingRequests = {};

  /// Счётчик для генерации уникальных ID запросов.
  int _requestId = 0;

  /// Completer для ожидания инициализации модели.
  Completer<bool>? _pendingInitialization;

  /// Флаг закрытия runner'а.
  bool _isClosed = false;

  AsrIsolateRunner._(this._responses, this._commands) {
    _responses.listen(_handleResponse);
  }

  /// Запущен ли изолят и готов ли принимать команды.
  bool get isRunning => !_isClosed;

  /// Создаёт и запускает фоновый изолят.
  ///
  /// После вызова изолят готов принимать команды через [initialize]
  /// и [transcribeFile].
  ///
  /// Использует RawReceivePort для разделения startup-логики
  /// и обработки последующих сообщений.
  static Future<AsrIsolateRunner> spawn() async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();

    initPort.handler = (dynamic message) {
      final commandPort = message as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    try {
      await Isolate.spawn(
        startAsrWorker,
        initPort.sendPort,
        debugName: 'AsrWorker',
      );
    } on Object {
      initPort.close();
      rethrow;
    }

    final (responses, commands) = await connection.future;
    return AsrIsolateRunner._(responses, commands);
  }

  /// Инициализирует модель в изоляте.
  ///
  /// Worker создаёт собственный recognizer с указанной моделью.
  /// Должен быть вызван после [spawn] и до [transcribeFile].
  Future<void> initialize(AsrModelEntity model, String modelPath) async {
    _ensureRunning();

    _pendingInitialization = Completer<bool>.sync();

    _commands.send(
      InitializeCommand(
        modelType: model.modelType,
        modelPath: modelPath,
        fileNames: model.getModelFileNames(),
      ),
    );

    final success = await _pendingInitialization!.future;
    _pendingInitialization = null;

    if (!success) {
      throw const AsrProcessingException('Failed to initialize model');
    }
  }

  /// Транскрибирует WAV файл в фоновом изоляте.
  ///
  /// Возвращает результат с текстом, токенами и временем обработки.
  /// Должен быть вызван после [initialize].
  Future<AsrResult> transcribeFile(String filePath) async {
    _ensureRunning();

    final requestId = _requestId++;
    final completer = Completer<AsrResult>.sync();
    _pendingRequests[requestId] = completer;

    _commands.send(TranscribeCommand(requestId: requestId, filePath: filePath));

    return completer.future;
  }

  /// Транскрибирует аудио буфер в фоновом изоляте.
  ///
  /// [samples] - PCM аудио данные в формате Float32 (-1.0 to 1.0).
  /// [sampleRate] - частота дискретизации (обычно 16000 Hz).
  ///
  /// Должен быть вызван после [initialize].
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate) async {
    _ensureRunning();

    final requestId = _requestId++;
    final completer = Completer<AsrResult>.sync();
    _pendingRequests[requestId] = completer;

    _commands.send(
      TranscribeAudioCommand(
        requestId: requestId,
        samples: samples,
        sampleRate: sampleRate,
      ),
    );

    return completer.future;
  }

  /// Завершает работу изолята и освобождает ресурсы.
  ///
  /// После вызова runner нельзя переиспользовать.
  /// Создайте новый через [spawn].
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;

    _commands.send(const DisposeCommand());

    // Отменяем все ожидающие запросы
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const AsrProcessingException('Runner was closed'),
        );
      }
    }
    _pendingRequests.clear();

    // Порт закроется после получения #exit от worker
  }

  // ===========================================================================
  // Приватные методы
  // ===========================================================================

  /// Обрабатывает сообщения от worker isolate.
  void _handleResponse(dynamic message) {
    // Worker уведомляет о завершении работы
    if (message == #exit) {
      _responses.close();
      return;
    }

    if (message is InitializeResponse) {
      message.success
          ? _pendingInitialization?.complete(message.success)
          : _pendingInitialization?.completeError(
              AsrProcessingException(
                message.error ?? 'Failed to initialize model',
              ),
            );
    } else if (message is TranscribeResponse) {
      final completer = _pendingRequests.remove(message.requestId);
      if (completer == null) return;

      if (message.error != null) {
        completer.completeError(AsrProcessingException(message.error!));
      } else {
        completer.complete(message.result!);
      }
    }
  }

  void _ensureRunning() {
    if (_isClosed) throw const AsrNotInitializedException();
  }
}
