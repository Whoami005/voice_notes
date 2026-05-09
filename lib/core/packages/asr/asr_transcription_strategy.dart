// DB-persisted enum. Int values are part of the DB schema.
// Never reorder existing entries; only append new variants at the end.
enum AsrTranscriptionStrategy {
  auto(0),
  streaming(1),
  singlePass(2),
  chunked(3),
  chunkedVad(4);

  const AsrTranscriptionStrategy(this.value);

  final int value;

  static AsrTranscriptionStrategy fromValue(int value) {
    for (final strategy in values) {
      if (strategy.value == value) return strategy;
    }

    throw StateError('Unknown transcription strategy: $value');
  }

  bool get supportsInteractiveProgress => switch (this) {
    AsrTranscriptionStrategy.streaming ||
    AsrTranscriptionStrategy.chunked ||
    AsrTranscriptionStrategy.chunkedVad => true,
    AsrTranscriptionStrategy.auto ||
    AsrTranscriptionStrategy.singlePass => false,
  };

  bool get supportsCancellation => supportsInteractiveProgress;

  bool get isAuto => this == auto;

  bool get isStreaming => this == streaming;

  bool get isSinglePass => this == singlePass;

  bool get isChunked => this == chunked;

  bool get isChunkedVad => this == chunkedVad;
}

enum AsrTranscribeStage {
  preparing,
  detectingSpeech,
  decoding,
  merging,
  finalizing,
}
