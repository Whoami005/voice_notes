import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_isolate_runner.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_planner.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/core/packages/asr/asr_vad_asset_installer.dart';
import 'package:voice_notes/core/packages/asr/asr_wav_duration_reader.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

/// Реализация ASR на базе sherpa-onnx. Поддерживает Whisper и Transducer
/// модели в file/buffer режимах. Вся FFI-работа выполняется в фоновом
/// изоляте через [AsrIsolateRunner] — main isolate является тонким фасадом.
@Singleton(as: AsrService)
class SherpaAsrService implements AsrService {
  AsrModelEntity? _currentModel;

  AsrIsolateRunner? _isolateRunner;

  // Дедуп по [_lastReadyEmit], чтобы не будить drain без реальной смены.
  final _stateController = StreamController<bool>.broadcast();
  bool _lastReadyEmit = false;

  @override
  bool get isInitialized => _isolateRunner?.isRunning ?? false;

  @override
  Stream<bool> get stateStream => _stateController.stream;

  @override
  AsrModelEntity? get currentModel => _currentModel;

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

    _currentModel = model;

    _emitReadyState();
  }

  @override
  Future<void> switchModel(AsrModelEntity newModel, String newModelPath) async {
    await unloadModel();
    await initialize(newModel, newModelPath);
  }

  @override
  Future<void> unloadModel() async {
    await _isolateRunner?.close();

    _isolateRunner = null;
    _currentModel = null;

    _emitReadyState();
  }

  @override
  Future<void> dispose() async {
    await unloadModel();
    if (!_stateController.isClosed) await _stateController.close();
  }

  @override
  Future<AsrResult> transcribeFile(
    String filePath, {
    void Function(AsrTranscribeProgress progress)? onProgress,
    AsrCancelToken? cancelToken,
    AsrTranscriptionStrategy strategyOverride = AsrTranscriptionStrategy.auto,
    Duration? audioDurationHint,
  }) async {
    _ensureInitialized();

    final file = File(filePath);
    if (!file.existsSync()) {
      throw AsrInvalidAudioException('File not found: $filePath');
    }

    final model = _currentModel!;
    final audioDuration =
        audioDurationHint ?? await AsrWavDurationReader.readDuration(filePath);
    final vadModelPath = await AsrVadAssetInstaller().resolveModelPath();

    final plan = AsrTranscriptionPlanner.resolve(
      model: model,
      audioDuration: audioDuration ?? Duration.zero,
      strategyOverride: strategyOverride,
      vadModelPath: vadModelPath,
    );

    return _isolateRunner!.transcribeFile(
      filePath,
      transcriptionPlan: plan,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate) async {
    _ensureInitialized();

    if (samples.isEmpty) {
      throw const AsrInvalidAudioException('Audio samples are empty');
    }

    return _isolateRunner!.transcribeAudio(samples, sampleRate);
  }

  void _ensureInitialized() {
    if (!isInitialized) throw const AsrNotInitializedException();
  }
}
