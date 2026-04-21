/// Базовая конфигурация ASR модели на main-isolate'е (для live-mic
/// streaming recognizer'а в `SherpaAsrService`). Worker-isolate движки
/// строят свои recognizer'ы напрямую, минуя этот класс.
sealed class AsrModelConfig {
  /// Путь к файлу токенов
  final String tokensPath;

  /// Количество потоков для вычислений
  final int numThreads;

  const AsrModelConfig({required this.tokensPath, this.numThreads = 2});
}

/// Конфигурация для Whisper моделей
class WhisperAsrConfig extends AsrModelConfig {
  /// Путь к encoder модели
  final String encoderPath;

  /// Путь к decoder модели
  final String decoderPath;

  const WhisperAsrConfig({
    required this.encoderPath,
    required this.decoderPath,
    required super.tokensPath,
    super.numThreads,
  });
}

/// Конфигурация для Transducer моделей (Parakeet TDT, Zipformer и др.)
class TransducerAsrConfig extends AsrModelConfig {
  /// Путь к encoder модели
  final String encoderPath;

  /// Путь к decoder модели
  final String decoderPath;

  /// Путь к joiner модели
  final String joinerPath;

  /// Тип модели для sherpa-onnx (`OfflineModelConfig.modelType` /
  /// `OnlineModelConfig.modelType`). Для NeMo Parakeet-style transducer ->
  /// `'nemo_transducer'`. Пустая строка = автодетект по загруженным файлам.
  final String modelType;

  const TransducerAsrConfig({
    required this.encoderPath,
    required this.decoderPath,
    required this.joinerPath,
    required super.tokensPath,
    super.numThreads,
    this.modelType = '',
  });
}
