import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/transcription_queue_cubit.dart';

void main() {
  group('TranscriptionQueueCubit (thin adapter)', () {
    late _FakeService service;

    setUp(() {
      service = _FakeService();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('emits snapshots from service stream', () async {
      final cubit = TranscriptionQueueCubit(service: service);

      expect(cubit.state.snapshot.queued, isEmpty);

      service.push(
        const TranscriptionQueueSnapshot(
          bootstrapState: QueueBootstrapReady(),
          queued: ['a'],
        ),
      );
      // Let stream event propagate.
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.snapshot.queued, ['a']);
      expect(cubit.state.bootstrapState.isReady, isTrue);

      await cubit.close();
    });

    test('retry/cancel/retryAll/clearFailedAll delegate to service', () async {
      final cubit = TranscriptionQueueCubit(service: service);

      await cubit.retry('u1');
      await cubit.cancel('u2');
      await cubit.retryAll();
      await cubit.clearFailedAll();
      await cubit.dismissFailed('u3');
      await cubit.retryBootstrap();
      cubit.onResume();

      expect(service.retryCalls, ['u1']);
      expect(service.cancelCalls, ['u2']);
      expect(service.retryAllCount, 1);
      expect(service.clearFailedAllCount, 1);
      expect(service.dismissFailedCalls, ['u3']);
      expect(service.retryBootstrapCount, 1);
      expect(service.resumeCount, 1);

      await cubit.close();
    });
  });
}

/// In-memory stand-in for `TranscriptionQueueService` (thin shell exposing
/// exactly what the cubit calls).
class _FakeService implements TranscriptionQueueService {
  final StreamController<TranscriptionQueueSnapshot> _controller =
      StreamController<TranscriptionQueueSnapshot>.broadcast();

  TranscriptionQueueSnapshot currentSnapshot =
      const TranscriptionQueueSnapshot();

  final List<String> retryCalls = <String>[];
  final List<String> cancelCalls = <String>[];
  final List<String> dismissFailedCalls = <String>[];
  int retryAllCount = 0;
  int clearFailedAllCount = 0;
  int retryBootstrapCount = 0;
  int resumeCount = 0;

  void push(TranscriptionQueueSnapshot snapshot) {
    currentSnapshot = snapshot;
    _controller.add(snapshot);
  }

  @override
  Stream<TranscriptionQueueSnapshot> get snapshots => _controller.stream;

  @override
  TranscriptionQueueSnapshot get current => currentSnapshot;

  @override
  Future<void> retry(String uid) async {
    retryCalls.add(uid);
  }

  @override
  Future<void> cancel(String uid) async {
    cancelCalls.add(uid);
  }

  @override
  Future<void> retryAll() async {
    retryAllCount++;
  }

  @override
  Future<void> clearFailedAll() async {
    clearFailedAllCount++;
  }

  @override
  Future<void> dismissFailed(String uid) async {
    dismissFailedCalls.add(uid);
  }

  @override
  Future<void> retryBootstrap() async {
    retryBootstrapCount++;
  }

  @override
  void resume() {
    resumeCount++;
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('FakeService: ${i.memberName} not stubbed');
}
