import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:record/record.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_exception.dart';
import 'package:voice_notes/core/packages/path/app_path_provider.dart';

/// Сервис для записи аудио
///
/// Управляет жизненным циклом аудио записи с правильной обработкой разрешений,
/// отслеживанием длительности и выводом в WAV формате для ASR.
@singleton
class AudioRecordingService {
  AudioRecordingService();

  // ==================== Конфигурация ====================

  /// Sample rate для совместимости с ASR (Whisper требует 16kHz)
  static const int sampleRate = 16000;

  /// Mono аудио для ASR
  static const int numChannels = 1;

  /// Битрейт
  static const int bitRate = 256000;

  /// Максимальная длительность записи (5 минут)
  static const Duration maxDuration = Duration(minutes: 5);

  // ==================== Состояние ====================

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentFilePath;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  Timer? _maxDurationTimer;

  final _durationController = StreamController<Duration>.broadcast();

  // Callback для auto-stop по достижению max duration
  void Function()? _onMaxDurationReached;

  // ==================== Getters ====================

  /// Активна ли запись
  bool get isRecording => _isRecording;

  /// Путь к текущему файлу записи (null если не записывается)
  String? get currentFilePath => _currentFilePath;

  /// Stream обновлений длительности (эмитит каждые 100ms во время записи)
  Stream<Duration> get durationStream => _durationController.stream;

  /// Текущая длительность записи
  Duration get currentDuration {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  // ==================== Разрешения ====================

  /// Проверить разрешение на использование микрофона
  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  // ==================== API Записи ====================

  /// Начать запись
  ///
  /// Запрашивает разрешение если нужно, создаёт временный WAV файл
  /// и начинает запись с настройками совместимыми с ASR.
  ///
  /// [onMaxDurationReached] - callback вызываемый при достижении max duration
  ///
  /// Выбрасывает:
  /// - [MicrophonePermissionDeniedException] если разрешение отклонено
  /// - [RecordingAlreadyActiveException] если запись уже активна
  /// - [RecordingFailedException] если запись не удалось начать
  Future<void> startRecording({void Function()? onMaxDurationReached}) async {
    if (_isRecording) throw const RecordingAlreadyActiveException();

    // Проверяем/запрашиваем разрешение
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) throw const MicrophonePermissionDeniedException();

    try {
      // Генерируем уникальный путь к файлу
      final tempDir = await AppPathProvider.getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentFilePath = '${tempDir.path}/recording_$timestamp.wav';

      // Начинаем запись с конфигурацией совместимой с ASR
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: sampleRate,
          numChannels: numChannels,
          bitRate: bitRate,
          autoGain: true,
          // androidConfig: AndroidRecordConfig(
          //   audioSource: AndroidAudioSource.mic,
          // ),
        ),
        path: _currentFilePath!,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _onMaxDurationReached = onMaxDurationReached;

      // Запускаем обновления длительности
      _startDurationUpdates();

      // Запускаем таймер max duration
      _startMaxDurationTimer();
    } catch (e) {
      _resetState();
      throw RecordingFailedException('Failed to start recording', e);
    }
  }

  /// Остановить запись и вернуть результат
  ///
  /// Останавливает запись и возвращает путь к WAV файлу.
  ///
  /// Выбрасывает:
  /// - [RecordingNotActiveException] если запись не активна
  /// - [RecordingFailedException] если остановка не удалась
  Future<RecordingResult> stopRecording() async {
    if (!_isRecording) throw const RecordingNotActiveException();

    try {
      final filePath = await _recorder.stop();
      final duration = currentDuration;

      _stopTimers();

      final result = RecordingResult(
        filePath: filePath ?? _currentFilePath!,
        duration: duration,
      );

      _resetState();

      return result;
    } catch (e) {
      _resetState();
      throw RecordingFailedException('Failed to stop recording', e);
    }
  }

  /// Отменить запись и удалить файл
  ///
  /// Останавливает запись без сохранения, удаляет временный файл.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();

      // Удаляем файл
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (file.existsSync()) unawaited(file.delete());
      }
    } catch (_) {
      // Игнорируем ошибки — отмена должна всегда завершаться успешно
    } finally {
      _stopTimers();
      _resetState();
    }
  }

  /// Освободить ресурсы
  @disposeMethod
  Future<void> dispose() async {
    await cancelRecording();
    await _durationController.close();
    await _recorder.dispose();
  }

  // ==================== Private методы ====================

  void _startDurationUpdates() {
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isRecording && !_durationController.isClosed) {
        _durationController.add(currentDuration);
      }
    });
  }

  void _startMaxDurationTimer() {
    _maxDurationTimer = Timer(maxDuration, () {
      if (_isRecording) {
        // Вызываем callback для auto-stop
        _onMaxDurationReached?.call();
      }
    });
  }

  void _stopTimers() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
  }

  void _resetState() {
    _isRecording = false;
    _currentFilePath = null;
    _recordingStartTime = null;
    _onMaxDurationReached = null;
  }
}

/// Результат завершённой записи
class RecordingResult {
  /// Путь к WAV файлу
  final String filePath;

  /// Длительность записи
  final Duration duration;

  const RecordingResult({required this.filePath, required this.duration});
}
