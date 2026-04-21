/// Набор файлов модели ASR. Sealed — кодирует разные форматы bundle'а через
/// разные подклассы, без stringly-typed ключей.
///
/// Используется в `InitializeCommand` (передаётся в worker isolate) и в
/// `AsrModelEntity.getModelFiles` как результат дефолтов/override'ов.
sealed class AsrModelFiles {
  /// Имя файла токенов — обязательное поле любого варианта.
  final String tokens;

  const AsrModelFiles({required this.tokens});

  /// Все имена файлов, относящиеся к модели. Используется для проверки
  /// существования файлов в бандле (`model_local_data_source`).
  Iterable<String> get allFileNames;
}

/// Whisper (encoder + decoder + tokens). Offline-only.
final class WhisperModelFiles extends AsrModelFiles {
  final String encoder;
  final String decoder;

  const WhisperModelFiles({
    required this.encoder,
    required this.decoder,
    required super.tokens,
  });

  @override
  Iterable<String> get allFileNames => [encoder, decoder, tokens];
}

/// Transducer (encoder + decoder + joiner + tokens). Используется и для
/// streaming (`OnlineRecognizer`), и для offline (`OfflineRecognizer` с
/// `OfflineTransducerModelConfig`) — различие на уровне
/// `AsrModelType`, а не набора файлов.
final class TransducerModelFiles extends AsrModelFiles {
  final String encoder;
  final String decoder;
  final String joiner;

  const TransducerModelFiles({
    required this.encoder,
    required this.decoder,
    required this.joiner,
    required super.tokens,
  });

  @override
  Iterable<String> get allFileNames => [encoder, decoder, joiner, tokens];
}
