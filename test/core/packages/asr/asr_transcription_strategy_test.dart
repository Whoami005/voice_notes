import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';

void main() {
  group('AsrTranscriptionStrategy persistence', () {
    test('keeps stable persisted values', () {
      expect(AsrTranscriptionStrategy.auto.value, 0);
      expect(AsrTranscriptionStrategy.streaming.value, 1);
      expect(AsrTranscriptionStrategy.singlePass.value, 2);
      expect(AsrTranscriptionStrategy.chunked.value, 3);
      expect(AsrTranscriptionStrategy.chunkedVad.value, 4);
    });

    test('restores strategy from persisted value', () {
      expect(
        AsrTranscriptionStrategy.fromValue(0),
        AsrTranscriptionStrategy.auto,
      );
      expect(
        AsrTranscriptionStrategy.fromValue(1),
        AsrTranscriptionStrategy.streaming,
      );
      expect(
        AsrTranscriptionStrategy.fromValue(2),
        AsrTranscriptionStrategy.singlePass,
      );
      expect(
        AsrTranscriptionStrategy.fromValue(3),
        AsrTranscriptionStrategy.chunked,
      );
      expect(
        AsrTranscriptionStrategy.fromValue(4),
        AsrTranscriptionStrategy.chunkedVad,
      );
    });

    test('throws on unknown persisted value', () {
      expect(
        () => AsrTranscriptionStrategy.fromValue(999),
        throwsA(isA<StateError>()),
      );
    });
  });
}
