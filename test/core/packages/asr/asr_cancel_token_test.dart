import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';

void main() {
  group('AsrCancelToken', () {
    test('initial state: isCancelled is false and whenCancelled pending', () {
      final token = AsrCancelToken();

      expect(token.isCancelled, isFalse);
      expectLater(token.whenCancelled, doesNotComplete);
    });

    test('cancel flips isCancelled and completes whenCancelled', () async {
      final token = AsrCancelToken();
      final future = expectLater(token.whenCancelled, completes);

      token.cancel();

      expect(token.isCancelled, isTrue);
      await future;
    });

    test('cancel is idempotent', () async {
      final token = AsrCancelToken()..cancel();

      expect(token.cancel, returnsNormally);
      expect(token.isCancelled, isTrue);
      await expectLater(token.whenCancelled, completes);
    });

    test(
      'multi-listener: both independent listeners fire after cancel',
      () async {
        final token = AsrCancelToken();
        var firstFired = false;
        var secondFired = false;

        unawaited(token.whenCancelled.then((_) => firstFired = true));
        unawaited(token.whenCancelled.then((_) => secondFired = true));

        token.cancel();
        await token.whenCancelled;
        // yield microtask so .then callbacks run
        await Future<void>.delayed(Duration.zero);

        expect(firstFired, isTrue);
        expect(secondFired, isTrue);
      },
    );
  });
}
