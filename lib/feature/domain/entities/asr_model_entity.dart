import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/asr/asr_model_files.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_plan.dart';

/// Идентификатор модели ASR.
///
/// Значения [value] сериализуются в БД и backup-файлы как `modelId`.
/// Менять или переиспользовать существующие строки нельзя.
enum AsrModelIdEnum {
  whisperTinyEn('whisper-tiny-en'),
  whisperSmall('whisper-small'),
  whisperMedium('whisper-medium'),
  parakeetTdtV3('parakeet-tdt-v3'),
  streamingZipformerEn('streaming-zipformer-en-2023-06-26'),
  streamingZipformerEn20M('streaming-zipformer-en-20M-2023-02-17');

  const AsrModelIdEnum(this.value);

  final String value;

  static AsrModelIdEnum? fromValue(String value) {
    for (final id in values) if (id.value == value) return id;

    return null;
  }
}

/// Тип модели ASR для конфигурации sherpa-onnx.
///
/// Влияет на выбор recognizer'а в воркере и набор обязательных файлов
/// модели. `streamingTransducer` запускается как `OnlineRecognizer`,
/// `offlineTransducer` — как `OfflineRecognizer` с тем же набором файлов
/// (encoder/decoder/joiner/tokens), но без streaming-интерфейса. Конкретный
/// sherpa-`modelType` задаётся в [AsrModelEntity.sherpaModelType] per-модель.
enum AsrModelType {
  /// Whisper модели (encoder + decoder + tokens). Offline-only.
  whisper,

  /// Transducer **streaming** модели (encoder + decoder + joiner + tokens).
  /// Загружается через `OnlineRecognizer`. Пример: streaming Zipformer.
  streamingTransducer,

  /// Transducer **offline** модели (тот же набор файлов, но bundle
  /// не поддерживает online-интерфейс). Загружается через
  /// `OfflineRecognizer` + `OfflineTransducerModelConfig`. Пример:
  /// NeMo Parakeet TDT v3.
  offlineTransducer,
}

class AsrModelEntity extends Equatable {
  final AsrModelIdEnum uuid;
  final String name;
  final String engine;
  final String size;
  final List<String> supportedLanguages;
  final String modelDirName;
  final AsrModelType modelType;
  final bool isDownloaded;
  final bool isSelected;

  /// Override имён файлов внутри bundle. Если задано — заменяет defaults
  /// из [getModelFiles]. Нужно для моделей с нестандартными именами
  /// (Zipformer-bundle'ы содержат encoder/decoder/joiner с epoch/avg/chunk
  /// suffix'ами, а не просто `encoder.int8.onnx`).
  final AsrModelFiles? customFiles;

  /// sherpa-onnx `modelType` для transducer-моделей. Пустая строка/null →
  /// sherpa автодетектит (стандартный Zipformer). `'nemo_transducer'` для
  /// NeMo-моделей. Используется в `OnlineModelConfig`/`OfflineModelConfig`.
  final String? sherpaModelType;

  /// Профиль выбора offline-стратегии.
  ///
  /// `null` для streaming-моделей, у которых execution-режим фиксирован.
  final AsrOfflineTranscriptionProfile? offlineTranscriptionProfile;

  const AsrModelEntity({
    required this.uuid,
    required this.name,
    required this.engine,
    required this.size,
    required this.supportedLanguages,
    required this.modelDirName,
    required this.modelType,
    this.isDownloaded = false,
    this.isSelected = false,
    this.customFiles,
    this.sherpaModelType,
    this.offlineTranscriptionProfile,
  });

  /// URL для скачивания модели с GitHub
  String get downloadUrl =>
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/$modelDirName.tar.bz2';

  /// Поддерживает ли модель streaming распознавание
  bool get supportsStreaming => modelType == AsrModelType.streamingTransducer;

  /// Поддерживает ли модель progress/cancel/partial-text для file decode.
  bool get supportsInteractiveTranscription =>
      supportsStreaming || offlineTranscriptionProfile != null;

  /// Типизированный набор файлов модели для конфигурации sherpa-onnx.
  ///
  /// Возвращает конкретный подтип [AsrModelFiles] в зависимости от
  /// [modelType]. [customFiles], если задан, переопределяет дефолты —
  /// подтип обязан соответствовать [modelType] (Whisper ↔ WhisperModelFiles,
  /// Transducer ↔ TransducerModelFiles), иначе будет runtime-несогласие
  /// в потребителях.
  AsrModelFiles getModelFiles() {
    if (customFiles != null) return customFiles!;

    return switch (modelType) {
      AsrModelType.whisper => _whisperDefaultFiles(),
      AsrModelType.streamingTransducer ||
      AsrModelType.offlineTransducer => const TransducerModelFiles(
        encoder: 'encoder.int8.onnx',
        decoder: 'decoder.int8.onnx',
        joiner: 'joiner.int8.onnx',
        tokens: 'tokens.txt',
      ),
    };
  }

  /// Whisper bundle'ы держат файлы под именами
  /// `<flavor>-{encoder,decoder,tokens}.*`, где `<flavor>` — всё, что после
  /// `sherpa-onnx-whisper-` в [modelDirName] (`tiny.en`, `small`,
  /// `medium` и т.д.). Деривируем префикс один раз — в трёх местах это был
  /// бы тройной `replaceFirst`.
  WhisperModelFiles _whisperDefaultFiles() {
    final flavor = modelDirName.replaceFirst('sherpa-onnx-whisper-', '');

    return WhisperModelFiles(
      encoder: '$flavor-encoder.int8.onnx',
      decoder: '$flavor-decoder.int8.onnx',
      tokens: '$flavor-tokens.txt',
    );
  }

  @override
  List<Object?> get props => [
    uuid,
    name,
    engine,
    size,
    supportedLanguages,
    modelDirName,
    modelType,
    isDownloaded,
    isSelected,
    customFiles,
    sherpaModelType,
    offlineTranscriptionProfile,
  ];

  /// Создать копию с изменёнными полями
  AsrModelEntity copyWith({
    AsrModelIdEnum? uuid,
    String? name,
    String? engine,
    String? size,
    List<String>? supportedLanguages,
    String? modelDirName,
    AsrModelType? modelType,
    bool? isDownloaded,
    bool? isSelected,
    AsrModelFiles? customFiles,
    String? sherpaModelType,
    AsrOfflineTranscriptionProfile? offlineTranscriptionProfile,
  }) {
    return AsrModelEntity(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      engine: engine ?? this.engine,
      size: size ?? this.size,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      modelDirName: modelDirName ?? this.modelDirName,
      modelType: modelType ?? this.modelType,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isSelected: isSelected ?? this.isSelected,
      customFiles: customFiles ?? this.customFiles,
      sherpaModelType: sherpaModelType ?? this.sherpaModelType,
      offlineTranscriptionProfile:
          offlineTranscriptionProfile ?? this.offlineTranscriptionProfile,
    );
  }

  /// Список доступных моделей для ска��ивания
  static const List<AsrModelEntity> availableModels = [
    // Whisper Tiny.en (~117MB int8)
    AsrModelEntity(
      uuid: AsrModelIdEnum.whisperTinyEn,
      name: 'Whisper Tiny',
      engine: 'OpenAI Whisper',
      size: '117 MB',
      supportedLanguages: ['English'],
      modelDirName: 'sherpa-onnx-whisper-tiny.en',
      modelType: AsrModelType.whisper,
      offlineTranscriptionProfile: AsrOfflineTranscriptionProfile.whisperTinyEn,
    ),

    // Whisper Small (~466MB)
    AsrModelEntity(
      uuid: AsrModelIdEnum.whisperSmall,
      name: 'Whisper Small',
      engine: 'OpenAI Whisper',
      size: '466 MB',
      supportedLanguages: _whisperLanguages,
      modelDirName: 'sherpa-onnx-whisper-small',
      modelType: AsrModelType.whisper,
      offlineTranscriptionProfile: AsrOfflineTranscriptionProfile.whisperSmall,
    ),

    // Whisper Medium (~1.5GB)
    AsrModelEntity(
      uuid: AsrModelIdEnum.whisperMedium,
      name: 'Whisper Medium',
      engine: 'OpenAI Whisper',
      size: '1.5 GB',
      supportedLanguages: _whisperLanguages,
      modelDirName: 'sherpa-onnx-whisper-medium',
      modelType: AsrModelType.whisper,
      offlineTranscriptionProfile: AsrOfflineTranscriptionProfile.whisperMedium,
    ),

    // Parakeet TDT v3 — offline-only вариант (bundle не поддерживает
    // OnlineRecognizer, verified эмпирически 2026-04-21). Streaming-UX
    // недоступен, но 25 европейских языков (включая русский) — единственная
    // не-Whisper offline опция в каталоге.
    AsrModelEntity(
      uuid: AsrModelIdEnum.parakeetTdtV3,
      name: 'Parakeet V3',
      engine: 'NVIDIA NeMo',
      size: '640 MB',
      supportedLanguages: _parakeetLanguages,
      modelDirName: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8',
      modelType: AsrModelType.offlineTransducer,
      sherpaModelType: 'nemo_transducer',
      offlineTranscriptionProfile:
          AsrOfflineTranscriptionProfile.defaultOffline,
    ),

    // Streaming Zipformer English (~85 MB int8) — подтверждённая online
    // модель из k2-fsa каталога. Bundle содержит файлы с chunk/avg-suffix
    // в имени, поэтому используем customFiles.
    AsrModelEntity(
      uuid: AsrModelIdEnum.streamingZipformerEn,
      name: 'Streaming Zipformer EN',
      engine: 'k2-fsa Zipformer',
      size: '85 MB',
      supportedLanguages: ['English'],
      modelDirName: 'sherpa-onnx-streaming-zipformer-en-2023-06-26',
      modelType: AsrModelType.streamingTransducer,
      customFiles: TransducerModelFiles(
        encoder: 'encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx',
        decoder: 'decoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx',
        joiner: 'joiner-epoch-99-avg-1-chunk-16-left-128.int8.onnx',
        tokens: 'tokens.txt',
      ),
    ),

    // Compact streaming Zipformer (~44 MB int8). Bundle от Feb 2023 с
    // упрощёнными именами файлов (без chunk/left-suffix'ов, как у более
    // свежих релизов). 20M параметров — лёгкий on-device вариант для
    // слабых устройств.
    AsrModelEntity(
      uuid: AsrModelIdEnum.streamingZipformerEn20M,
      name: 'Streaming Zipformer EN 20M',
      engine: 'k2-fsa Zipformer',
      size: '44 MB',
      supportedLanguages: ['English'],
      modelDirName: 'sherpa-onnx-streaming-zipformer-en-20M-2023-02-17',
      modelType: AsrModelType.streamingTransducer,
      customFiles: TransducerModelFiles(
        encoder: 'encoder-epoch-99-avg-1.int8.onnx',
        decoder: 'decoder-epoch-99-avg-1.int8.onnx',
        joiner: 'joiner-epoch-99-avg-1.int8.onnx',
        tokens: 'tokens.txt',
      ),
    ),
  ];

  /// 25 европейских языков поддерживаемых Parakeet V3.
  static const List<String> _parakeetLanguages = [
    'Bulgarian',
    'Croatian',
    'Czech',
    'Danish',
    'Dutch',
    'English',
    'Finnish',
    'French',
    'German',
    'Greek',
    'Hungarian',
    'Italian',
    'Latvian',
    'Lithuanian',
    'Norwegian',
    'Polish',
    'Portuguese',
    'Romanian',
    'Russian',
    'Slovak',
    'Slovenian',
    'Spanish',
    'Swedish',
    'Turkish',
    'Ukrainian',
  ];

  /// 99 языков поддерживаемых Whisper
  static const List<String> _whisperLanguages = [
    'Afrikaans',
    'Albanian',
    'Amharic',
    'Arabic',
    'Armenian',
    'Assamese',
    'Azerbaijani',
    'Bashkir',
    'Basque',
    'Belarusian',
    'Bengali',
    'Bosnian',
    'Breton',
    'Bulgarian',
    'Burmese',
    'Catalan',
    'Chinese',
    'Croatian',
    'Czech',
    'Danish',
    'Dutch',
    'English',
    'Estonian',
    'Faroese',
    'Finnish',
    'French',
    'Galician',
    'Georgian',
    'German',
    'Greek',
    'Gujarati',
    'Haitian Creole',
    'Hausa',
    'Hawaiian',
    'Hebrew',
    'Hindi',
    'Hungarian',
    'Icelandic',
    'Indonesian',
    'Italian',
    'Japanese',
    'Javanese',
    'Kannada',
    'Kazakh',
    'Khmer',
    'Korean',
    'Lao',
    'Latin',
    'Latvian',
    'Lingala',
    'Lithuanian',
    'Luxembourgish',
    'Macedonian',
    'Malagasy',
    'Malay',
    'Malayalam',
    'Maltese',
    'Maori',
    'Marathi',
    'Mongolian',
    'Nepali',
    'Norwegian',
    'Nynorsk',
    'Occitan',
    'Pashto',
    'Persian',
    'Polish',
    'Portuguese',
    'Punjabi',
    'Romanian',
    'Russian',
    'Sanskrit',
    'Serbian',
    'Shona',
    'Sindhi',
    'Sinhala',
    'Slovak',
    'Slovenian',
    'Somali',
    'Spanish',
    'Sundanese',
    'Swahili',
    'Swedish',
    'Tagalog',
    'Tajik',
    'Tamil',
    'Tatar',
    'Telugu',
    'Thai',
    'Tibetan',
    'Turkish',
    'Turkmen',
    'Ukrainian',
    'Urdu',
    'Uzbek',
    'Vietnamese',
    'Welsh',
    'Yiddish',
    'Yoruba',
  ];
}
