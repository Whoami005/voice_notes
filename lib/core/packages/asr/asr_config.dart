/// Базовая конфигурация ASR модели
sealed class AsrModelConfig {
  /// Путь к файлу токенов
  final String tokensPath;

  /// Количество потоков для вычислений
  final int numThreads;

  const AsrModelConfig({required this.tokensPath, this.numThreads = 2});

  /// Поддерживает ли конфигурация streaming распознавание
  bool get supportsStreaming;
}

/// Конфигурация для Whisper моделей
class WhisperAsrConfig extends AsrModelConfig {
  /// Путь к encoder модели
  final String encoderPath;

  /// Путь к decoder модели
  final String decoderPath;

  /// Язык для распознавания (null = auto-detect)
  final String? language;

  /// Задача: 'transcribe' или 'translate'
  final String task;

  /// Количество tail padding samples
  final int tailPaddings;

  const WhisperAsrConfig({
    required this.encoderPath,
    required this.decoderPath,
    required super.tokensPath,
    super.numThreads,
    this.language,
    this.task = 'transcribe',
    this.tailPaddings = -1,
  });

  @override
  bool get supportsStreaming => false;
}

/// Конфигурация для Transducer моделей (Parakeet TDT, Zipformer и др.)
class TransducerAsrConfig extends AsrModelConfig {
  /// Путь к encoder модели
  final String encoderPath;

  /// Путь к decoder модели
  final String decoderPath;

  /// Путь к joiner модели
  final String joinerPath;

  const TransducerAsrConfig({
    required this.encoderPath,
    required this.decoderPath,
    required this.joinerPath,
    required super.tokensPath,
    super.numThreads,
  });

  @override
  bool get supportsStreaming => true;
}
