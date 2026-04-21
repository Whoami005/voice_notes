import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_commands.dart';
import 'package:voice_notes/core/packages/asr/asr_isolate/asr_isolate_runner.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';

/// Fake-worker поверх in-memory `SendPort`/`ReceivePort` pair. Не использует
/// реальный `Isolate.spawn` и не требует FFI-bindings — тестируем только
/// protocol-логику runner'а.
class _FakeWorker {
  final ReceivePort _port = ReceivePort();
  final StreamController<AsrCommand> _controller =
      StreamController<AsrCommand>.broadcast();

  /// Inbox всех commands, которые runner прислал воркеру. Для verify в тестах.
  final List<AsrCommand> inbox = [];

  /// Port, в который runner шлёт commands.
  SendPort get commandsSendPort => _port.sendPort;

  _FakeWorker() {
    _port.listen((msg) {
      if (msg is AsrCommand) {
        inbox.add(msg);
        _controller.add(msg);
      }
    });
  }

  /// Ожидает первую команду указанного типа.
  Future<T> awaitCommand<T extends AsrCommand>() async {
    return _controller.stream.firstWhere((msg) => msg is T).then((v) => v as T);
  }

  Future<void> close() async {
    _port.close();
    await _controller.close();
  }
}

void main() {
  late _FakeWorker worker;
  late ReceivePort runnerResponsesPort;
  late AsrIsolateRunner runner;

  setUp(() {
    worker = _FakeWorker();
    runnerResponsesPort = ReceivePort();
    runner = AsrIsolateRunner.forTesting(
      responses: runnerResponsesPort,
      commands: worker.commandsSendPort,
    );
  });

  tearDown(() async {
    await worker.close();
    runnerResponsesPort.close();
  });

  /// Эмулирует отправку ответа от воркера.
  void sendFromWorker(AsrResponse response) {
    runnerResponsesPort.sendPort.send(response);
  }

  group('AsrIsolateRunner.transcribeFile', () {
    test(
      'happy path: progress events + ok → onProgress N раз + Future ok',
      () async {
        final progressEvents = <AsrTranscribeProgress>[];

        final future = runner.transcribeFile(
          '/tmp/test.wav',
          onProgress: progressEvents.add,
        );

        // Дождаться пока runner зашлёт TranscribeCommand.
        final cmd = await worker.awaitCommand<TranscribeCommand>();
        expect(cmd.filePath, '/tmp/test.wav');

        // Эмулируем 3 progress-события + финальный ok.
        for (var i = 1; i <= 3; i++) {
          sendFromWorker(
            TranscribeProgressResponse(
              requestId: cmd.requestId,
              progress: i / 3,
              partialText: 'p$i',
              processedSeconds: i * 1.0,
              totalSeconds: 3,
            ),
          );
        }
        sendFromWorker(
          TranscribeOkResponse(cmd.requestId, const AsrResult(text: 'done')),
        );

        final result = await future;
        expect(result.text, 'done');
        expect(progressEvents, hasLength(3));
        expect(progressEvents.last.percent, 100);
        expect(progressEvents.last.partialText, 'p3');
      },
    );

    test(
      'cancel: cancelToken → CancelTranscribeCommand → AsrCancelledException',
      () async {
        final token = AsrCancelToken();
        final future = runner.transcribeFile(
          '/tmp/test.wav',
          cancelToken: token,
        );

        final cmd = await worker.awaitCommand<TranscribeCommand>();

        // Отменяем токен — runner должен послать CancelTranscribeCommand.
        token.cancel();
        final cancelCmd = await worker.awaitCommand<CancelTranscribeCommand>();
        expect(cancelCmd.requestId, cmd.requestId);

        // Эмулируем cancelled-response от воркера.
        sendFromWorker(TranscribeCancelledResponse(cmd.requestId));

        await expectLater(future, throwsA(isA<AsrCancelledException>()));
      },
    );

    test(
      'disposed flag: late cancel after success does NOT send stale cancel',
      () async {
        final token = AsrCancelToken();
        final future = runner.transcribeFile(
          '/tmp/test.wav',
          cancelToken: token,
        );

        final cmd = await worker.awaitCommand<TranscribeCommand>();

        // Сначала присылаем ok — request terminated, disposed = true.
        sendFromWorker(
          TranscribeOkResponse(cmd.requestId, const AsrResult(text: 'done')),
        );
        await future;

        // Теперь поздний cancel. Не должен слать CancelTranscribeCommand.
        worker.inbox.clear();
        token.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(worker.inbox.whereType<CancelTranscribeCommand>(), isEmpty);
      },
    );

    test('TranscribeBusyResponse → AsrWorkerBusyException', () async {
      final future = runner.transcribeFile('/tmp/test.wav');
      final cmd = await worker.awaitCommand<TranscribeCommand>();

      sendFromWorker(TranscribeBusyResponse(cmd.requestId));

      await expectLater(future, throwsA(isA<AsrWorkerBusyException>()));
    });

    test('failed with generic error → AsrProcessingException', () async {
      final future = runner.transcribeFile('/tmp/test.wav');
      final cmd = await worker.awaitCommand<TranscribeCommand>();

      sendFromWorker(TranscribeFailedResponse(cmd.requestId, 'disk exploded'));

      await expectLater(
        future,
        throwsA(
          isA<AsrProcessingException>().having(
            (e) => e.message,
            'message',
            'disk exploded',
          ),
        ),
      );
    });

    test('progress after terminal response is ignored', () async {
      final progressEvents = <AsrTranscribeProgress>[];

      final future = runner.transcribeFile(
        '/tmp/test.wav',
        onProgress: progressEvents.add,
      );
      final cmd = await worker.awaitCommand<TranscribeCommand>();

      sendFromWorker(
        TranscribeOkResponse(cmd.requestId, const AsrResult(text: 'done')),
      );
      await future;

      // Запоздавший progress — не должен доставляться.
      sendFromWorker(
        TranscribeProgressResponse(
          requestId: cmd.requestId,
          progress: 1,
          partialText: 'stale',
          processedSeconds: 10,
          totalSeconds: 10,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(progressEvents, isEmpty);
    });
  });
}
