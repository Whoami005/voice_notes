import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';

void main() {
  group('AsrException hierarchy', () {
    test('AsrCancelledException is AsrException subtype', () {
      const e = AsrCancelledException();
      expect(e, isA<AsrException>());
      expect(e.toString(), contains('cancelled'));
    });

    test('AsrWorkerBusyException extends AsrProcessingException', () {
      const e = AsrWorkerBusyException();
      expect(e, isA<AsrProcessingException>());
      expect(e, isA<AsrException>());
    });

    test('AsrStreamingBusyException is AsrException subtype', () {
      const e = AsrStreamingBusyException();
      expect(e, isA<AsrException>());
    });

    test('sealed switch covers new exceptions', () {
      String describe(AsrException e) => switch (e) {
        AsrNotInitializedException() => 'not-init',
        AsrModelNotFoundException() => 'model-404',
        AsrInvalidAudioException() => 'bad-audio',
        AsrProcessingException() => 'processing',
        AsrStreamingNotSupportedException() => 'stream-unsupported',
        AsrStreamingAlreadyActiveException() => 'stream-active',
        AsrStreamingNotActiveException() => 'stream-inactive',
        AsrCancelledException() => 'cancelled',
        AsrStreamingBusyException() => 'stream-busy',
      };

      expect(describe(const AsrCancelledException()), 'cancelled');
      expect(describe(const AsrStreamingBusyException()), 'stream-busy');
      // Busy is processing-subtype; switch matches parent first.
      expect(describe(const AsrWorkerBusyException()), 'processing');
    });
  });
}
