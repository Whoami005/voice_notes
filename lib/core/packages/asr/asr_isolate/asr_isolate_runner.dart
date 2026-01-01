import 'dart:async';
import 'dart:isolate';

import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_commands.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_isolate_worker.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Управляет фоновым изолятом для офлайн ASR транскрибации.
///
/// Изолят создаётся один раз при вызове [spawn] и живёт до [close].
/// Это позволяет избежать повторной загрузки модели (~500ms-2s)
/// при каждой транскрибации.
///
/// Пример использования:
/// ```dart
/// final runner = AsrIsolateRunner();
/// await runner.spawn();
/// await runner.initialize(model, modelPath);
/// final result = await runner.transcribeFile(filePath);
/// await runner.close();
/// ```
class AsrIsolateRunner {
  Isolate? _isolate;
  ReceivePort? _responses;
  SendPort? _commands;

  final _isolateReady = Completer<void>.sync();
  Completer<AsrResult>? _pendingTranscription;
  Completer<bool>? _pendingInitialization;

  /// Запущен ли изолят и готов ли принимать команды.
  bool get isRunning => _isolate != null && _isolateReady.isCompleted;

  /// Создаёт и запускает фоновый изолят.
  ///
  /// После вызова изолят готов принимать команды через [initialize]
  /// и [transcribeFile].
  Future<void> spawn() async {
    if (_isolate != null) return;

    _responses = ReceivePort();
    _responses!.listen(_handleResponse);

    _isolate = await Isolate.spawn(startAsrWorker, _responses!.sendPort);

    // Ждём пока worker отправит свой SendPort
    await _isolateReady.future;
  }

  /// Инициализирует модель в изоляте.
  ///
  /// Worker создаёт собственный recognizer с указанной моделью.
  /// Должен быть вызван после [spawn] и до [transcribeFile].
  Future<void> initialize(AsrModelEntity model, String modelPath) async {
    _ensureRunning();

    _pendingInitialization = Completer<bool>.sync();

    _commands!.send(
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

    _pendingTranscription = Completer<AsrResult>.sync();

    _commands!.send(TranscribeCommand(filePath: filePath));

    final result = await _pendingTranscription!.future;
    _pendingTranscription = null;

    return result;
  }

  /// Завершает работу изолята и освобождает ресурсы.
  ///
  /// После вызова runner можно переиспользовать, вызвав [spawn] снова.
  Future<void> close() async {
    if (_isolate == null) return;

    _commands?.send(const DisposeCommand());

    // Даём worker'у время освободить ресурсы
    await Future<void>.delayed(const Duration(milliseconds: 50));

    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _commands = null;

    _responses?.close();
    _responses = null;
  }

  // ===========================================================================
  // Приватные методы
  // ===========================================================================

  /// Обрабатывает сообщения от worker isolate.
  void _handleResponse(dynamic message) {
    // Первое сообщение - SendPort для отправки команд
    if (message is SendPort) {
      _commands = message;
      _isolateReady.complete();
      return;
    }

    // Остальные - ответы на команды
    if (message is InitializeResponse) {
      _pendingInitialization?.complete(message.success);
    } else if (message is TranscribeResponse) {
      if (message.error != null) {
        _pendingTranscription?.completeError(
          AsrProcessingException(message.error!),
        );
      } else {
        _pendingTranscription?.complete(message.result!);
      }
    }
  }

  void _ensureRunning() {
    if (_isolate == null || _commands == null) {
      throw const AsrNotInitializedException();
    }
  }
}
