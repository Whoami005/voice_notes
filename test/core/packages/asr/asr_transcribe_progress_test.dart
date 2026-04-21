import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';

void main() {
  group('AsrTranscribeProgress', () {
    const a = AsrTranscribeProgress(
      progress: 0.5,
      partialText: 'hello',
      processedAudio: Duration(seconds: 15),
      totalAudio: Duration(seconds: 30),
    );

    test('construction: all fields accessible', () {
      expect(a.progress, 0.5);
      expect(a.partialText, 'hello');
      expect(a.processedAudio, const Duration(seconds: 15));
      expect(a.totalAudio, const Duration(seconds: 30));
    });

    test('equality via Equatable', () {
      const b = AsrTranscribeProgress(
        progress: 0.5,
        partialText: 'hello',
        processedAudio: Duration(seconds: 15),
        totalAudio: Duration(seconds: 30),
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when progress differs', () {
      const b = AsrTranscribeProgress(
        progress: 0.6,
        partialText: 'hello',
        processedAudio: Duration(seconds: 15),
        totalAudio: Duration(seconds: 30),
      );

      expect(a, isNot(equals(b)));
    });

    test('percent getter floors to avoid premature 100%', () {
      const p = AsrTranscribeProgress(
        progress: 0.347,
        partialText: '',
        processedAudio: Duration(seconds: 10),
        totalAudio: Duration(seconds: 30),
      );

      expect(p.percent, 34);
    });

    test('percent getter returns 0 for initial progress', () {
      const p = AsrTranscribeProgress(
        progress: 0.0,
        partialText: '',
        processedAudio: Duration.zero,
        totalAudio: Duration(seconds: 30),
      );

      expect(p.percent, 0);
    });

    test('percent getter returns 100 only at full progress', () {
      const p = AsrTranscribeProgress(
        progress: 1.0,
        partialText: 'done',
        processedAudio: Duration(seconds: 30),
        totalAudio: Duration(seconds: 30),
      );

      expect(p.percent, 100);
    });
  });
}
