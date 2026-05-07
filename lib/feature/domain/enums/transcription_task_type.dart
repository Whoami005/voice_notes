enum TranscriptionTaskType {
  transcribe(0),
  translate(1);

  final int value;

  const TranscriptionTaskType(this.value);

  static TranscriptionTaskType fromValue(int value) {
    for (final taskType in values) {
      if (taskType.value == value) return taskType;
    }

    throw StateError('Unknown transcription task type: $value');
  }
}
