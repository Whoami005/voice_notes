enum AsrTranscriptionStrategy {
  auto,
  streaming,
  singlePass,
  chunked,
  chunkedVad;

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
