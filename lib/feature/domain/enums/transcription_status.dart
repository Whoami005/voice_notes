// DB-persisted enum. Int values are part of the DB schema.
// Never reorder existing entries; only append new variants at the end.
enum TranscriptionStatus {
  queued(0),
  transcribing(1),
  completed(2),
  failed(3),
  cancelled(4);

  const TranscriptionStatus(this.value);

  final int value;

  // TODO(log): emit warning when unknown int value is encountered —
  // need a logger facade first.
  static TranscriptionStatus fromValue(int value) =>
      values.firstWhere((s) => s.value == value, orElse: () => failed);

  bool get isFailed => this == failed;

  bool get isCompleted => this == completed;

  bool get isCancelled => this == cancelled;

  bool get isQueued => this == queued;

  bool get isTranscribing => this == transcribing;
}
