import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_engine.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';

void main() {
  group('AsrEngineResult', () {
    test('ok wraps result', () {
      const result = AsrResult(text: 'hello');

      expect(const AsrEngineOk(result).result, result);
    });

    test('cancelled can be created', () {
      const result = AsrEngineCancelled();

      expect(result, isA<AsrEngineCancelled>());
    });
  });
}
