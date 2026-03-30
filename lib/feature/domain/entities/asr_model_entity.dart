import 'package:equatable/equatable.dart';

/// Тип модели ASR для конфигурации sherpa-onnx
enum AsrModelType {
  /// Whisper модели (encoder + decoder + tokens)
  whisper,

  /// Parakeet TDT модели (encoder + decoder + joiner + tokens)
  parakeetTdt,
}

class AsrModelEntity extends Equatable {
  final String uuid;
  final String name;
  final String engine;
  final String size;
  final String languageLabel;
  final List<String> supportedLanguages;
  final String description;
  final String modelDirName;
  final AsrModelType modelType;
  final bool isDownloaded;
  final bool isSelected;
  final double? downloadProgress;

  const AsrModelEntity({
    required this.uuid,
    required this.name,
    required this.engine,
    required this.size,
    required this.languageLabel,
    required this.supportedLanguages,
    required this.description,
    required this.modelDirName,
    required this.modelType,
    this.isDownloaded = false,
    this.isSelected = false,
    this.downloadProgress,
  });

  /// URL для скачивания модели с GitHub
  String get downloadUrl =>
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/$modelDirName.tar.bz2';

  /// Поддерживает ли модель streaming распознавание
  bool get supportsStreaming => modelType == AsrModelType.parakeetTdt;

  /// Получить имена файлов модели для конфигурации sherpa-onnx
  ///
  /// Возвращает Map с ключами:
  /// - 'encoder' - путь к encoder модели
  /// - 'decoder' - путь к decoder модели
  /// - 'joiner' - путь к joiner модели (только для Transducer)
  /// - 'tokens' - путь к файлу токенов
  Map<String, String> getModelFileNames() {
    return switch (modelType) {
      AsrModelType.whisper => {
        'encoder': _whisperEncoderFileName,
        'decoder': _whisperDecoderFileName,
        'tokens': _whisperTokensFileName,
      },
      AsrModelType.parakeetTdt => {
        'encoder': 'encoder.int8.onnx',
        'decoder': 'decoder.int8.onnx',
        'joiner': 'joiner.int8.onnx',
        'tokens': 'tokens.txt',
      },
    };
  }

  /// Имя файла encoder для Whisper модели
  String get _whisperEncoderFileName {
    // sherpa-onnx-whisper-tiny.en -> tiny.en
    // sherpa-onnx-whisper-small -> small
    final modelName = modelDirName.replaceFirst('sherpa-onnx-whisper-', '');
    return '$modelName-encoder.int8.onnx';
  }

  /// Имя файла decoder для Whisper модели
  String get _whisperDecoderFileName {
    final modelName = modelDirName.replaceFirst('sherpa-onnx-whisper-', '');
    return '$modelName-decoder.int8.onnx';
  }

  /// Имя файла tokens для Whisper модели
  String get _whisperTokensFileName {
    final modelName = modelDirName.replaceFirst('sherpa-onnx-whisper-', '');
    return '$modelName-tokens.txt';
  }

  @override
  List<Object?> get props => [
    uuid,
    name,
    engine,
    size,
    languageLabel,
    supportedLanguages,
    description,
    modelDirName,
    modelType,
    isDownloaded,
    isSelected,
    downloadProgress,
  ];

  /// Создать копию с изменёнными полями
  AsrModelEntity copyWith({
    String? uuid,
    String? name,
    String? engine,
    String? size,
    String? languageLabel,
    List<String>? supportedLanguages,
    String? description,
    String? modelDirName,
    AsrModelType? modelType,
    bool? isDownloaded,
    bool? isSelected,
    double? downloadProgress,
  }) {
    return AsrModelEntity(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      engine: engine ?? this.engine,
      size: size ?? this.size,
      languageLabel: languageLabel ?? this.languageLabel,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      description: description ?? this.description,
      modelDirName: modelDirName ?? this.modelDirName,
      modelType: modelType ?? this.modelType,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isSelected: isSelected ?? this.isSelected,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  /// Список доступных моделей для скачивания
  static const List<AsrModelEntity> availableModels = [
    // Whisper Tiny.en (~117MB int8)
    AsrModelEntity(
      uuid: 'whisper-tiny-en',
      name: 'Whisper Tiny',
      engine: 'OpenAI Whisper',
      size: '117 MB',
      languageLabel: 'English',
      supportedLanguages: ['English'],
      description: 'Самая быстрая модель. Только английский язык.',
      modelDirName: 'sherpa-onnx-whisper-tiny.en',
      modelType: AsrModelType.whisper,
    ),

    // Whisper Small (~466MB)
    AsrModelEntity(
      uuid: 'whisper-small',
      name: 'Whisper Small',
      engine: 'OpenAI Whisper',
      size: '466 MB',
      languageLabel: '99 языков',
      supportedLanguages: _whisperLanguages,
      description:
          'Быстрая модель с хорошим качеством. '
          'Рекомендуется для большинства задач.',
      modelDirName: 'sherpa-onnx-whisper-small',
      modelType: AsrModelType.whisper,
    ),

    // Whisper Medium (~1.5GB)
    AsrModelEntity(
      uuid: 'whisper-medium',
      name: 'Whisper Medium',
      engine: 'OpenAI Whisper',
      size: '1.5 GB',
      languageLabel: '99 языков',
      supportedLanguages: _whisperLanguages,
      description:
          'Более точная модель для сложных аудиозаписей '
          'с шумом или акцентом.',
      modelDirName: 'sherpa-onnx-whisper-medium',
      modelType: AsrModelType.whisper,
    ),

    // Parakeet TDT v3 (~640MB int8)
    // AsrModelEntity(
    //   uuid: 'parakeet-tdt-v3',
    //   name: 'Parakeet V3',
    //   engine: 'NVIDIA NeMo',
    //   size: '640 MB',
    //   languageLabel: '25 европейских языков',
    //   supportedLanguages: _parakeetLanguages,
    //   description:
    //       'Компактная модель для европейских языков. '
    //       'Быстрая работа на устройстве.',
    //   modelDirName: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8',
    //   modelType: AsrModelType.parakeetTdt,
    // ),
  ];

  /// 25 европейских языков поддерживаемых Parakeet V3
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
