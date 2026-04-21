import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/sherpa_asr_service.dart';

void main() {
  group('SherpaAsrService.assertStreamingNotBusy', () {
    test('fileStreamingActive == false → passes silently', () {
      expect(
        () =>
            SherpaAsrService.assertStreamingNotBusy(fileStreamingActive: false),
        returnsNormally,
      );
    });

    test('fileStreamingActive == true → throws AsrStreamingBusyException', () {
      expect(
        () =>
            SherpaAsrService.assertStreamingNotBusy(fileStreamingActive: true),
        throwsA(isA<AsrStreamingBusyException>()),
      );
    });
  });
}
