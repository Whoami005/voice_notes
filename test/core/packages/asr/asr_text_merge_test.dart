import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_text_merge.dart';

void main() {
  group('AsrTextMerge', () {
    test('returns right text when left is empty', () {
      expect(AsrTextMerge.merge('', 'hello world'), 'hello world');
    });

    test('deduplicates overlapping suffix/prefix words', () {
      expect(
        AsrTextMerge.merge('hello world from', 'from the other side'),
        'hello world from the other side',
      );
    });

    test('concatenates when overlap is absent', () {
      expect(
        AsrTextMerge.merge('hello world', 'general kenobi'),
        'hello world general kenobi',
      );
    });
  });
}
