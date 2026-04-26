import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:record/record.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_exception.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';

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
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  final _durationController = StreamController<Duration>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();

  /// Нижняя граница нормализации dBFS → [0, 1]. Значения тише -60 dBFS
  /// считаем тишиной (mapped в 0).
  static const double _silenceFloorDb = -60;

  /// Интервал, с которым `record` пакет эмитит amplitude-сэмплы.
  static const Duration _amplitudeInterval = Duration(milliseconds: 100);

  // Callback для auto-stop по достижению max duration
  void Function()? _onMaxDurationReached;

  // ==================== Getters ====================

  /// Активна ли запись
  bool get isRecording => _isRecording;

  /// Путь к текущему файлу записи (null если не записывается)
  String? get currentFilePath => _currentFilePath;

  /// Stream обновлений длительности (эмитит каждые 100ms во время записи)
  Stream<Duration> get durationStream => _durationController.stream;

  /// Stream нормализованной амплитуды микрофона в диапазоне [0.0, 1.0].
  /// Эмитит каждые 100ms во время записи.
  Stream<double> get amplitudeStream => _amplitudeController.stream;

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
  /// Запрашивает разрешение если нужно, создаёт WAV-файл в permanent-директории
  /// `Documents/audio/recordings/{noteUuid}.wav` и начинает запись с настройками
  /// совместимыми с ASR.
  ///
  /// [noteUuid] — идентификатор будущей заметки; используется как имя файла,
  /// чтобы после транскрибации можно было сохранить заметку с тем же uuid
  /// и прицепить к ней сохранённый оригинал.
  ///
  /// [onMaxDurationReached] — callback, вызываемый при достижении max duration.
  ///
  /// Выбрасывает:
  /// - [MicrophonePermissionDeniedException] если разрешение отклонено
  /// - [RecordingAlreadyActiveException] если запись уже активна
  /// - [RecordingFailedException] если запись не удалось начать
  Future<void> startRecording({
    required String noteUuid,
    void Function()? onMaxDurationReached,
  }) async {
    if (_isRecording) throw const RecordingAlreadyActiveException();

    // Проверяем/запрашиваем разрешение
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) throw const MicrophonePermissionDeniedException();

    try {
      // Пишем сразу в permanent-директорию — никаких temp → copy шагов.
      final recordingsDir = await AudioPaths.recordingsDir;
      _currentFilePath = '$recordingsDir/$noteUuid.wav';

      // Начинаем запись с конфигурацией совместимой с ASR
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: sampleRate,
          numChannels: numChannels,
          bitRate: bitRate,
          autoGain: true,
        ),
        path: _currentFilePath!,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      _onMaxDurationReached = onMaxDurationReached;

      // Запускаем обновления длительности
      _startDurationUpdates();

      // Запускаем стрим амплитуды
      _startAmplitudeUpdates();

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
    await _amplitudeController.close();
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

  void _startAmplitudeUpdates() {
    final stream = _recorder.onAmplitudeChanged(_amplitudeInterval);
    _amplitudeSubscription = stream.listen(
      (amp) {
        if (!_isRecording || _amplitudeController.isClosed) return;

        // Нормализация: значения тише `_silenceFloorDb` → 0.0, 0 dBFS → 1.0.
        final normalized = ((amp.current - _silenceFloorDb) / -_silenceFloorDb)
            .clamp(0.0, 1.0);
        _amplitudeController.add(normalized);
      },
      // Источник — внешний (`record` пакет), ошибки прокидываем подписчикам,
      // чтобы Cubit мог их залогировать через `addError`. Без этого падение
      // улетало бы в `Zone.current.handleUncaughtError`.
      onError: (Object e, StackTrace s) {
        if (!_amplitudeController.isClosed) {
          _amplitudeController.addError(e, s);
        }
      },
    );
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
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
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
