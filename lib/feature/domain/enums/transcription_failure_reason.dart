// DB-persisted enum. Int values are part of the DB schema.
// Never reorder existing entries; only append new variants at the end.
enum TranscriptionFailureReason {
  unknown(0),
  noModelSelected(1),
  modelLoadFailed(2),
  transcriptionFailed(3),
  audioFileMissing(4),
  audioFileCorrupted(5),
  transcriptionTimedOut(6);

  final int value;

  const TranscriptionFailureReason(this.value);

  // TODO(log): emit warning when unknown int value is encountered —
  // need a logger facade first.
  static TranscriptionFailureReason fromValue(int value) =>
      values.firstWhere((r) => r.value == value, orElse: () => unknown);

  bool get isPermanent => switch (this) {
    audioFileMissing || audioFileCorrupted => true,
    _ => false,
  };
}
