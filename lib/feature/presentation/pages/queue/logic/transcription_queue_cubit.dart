import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';
import 'package:voice_notes/feature/domain/enums/queue_runtime_reason.dart';

part 'transcription_queue_state.dart';

/// UI-адаптер очереди транскрибации.
///
/// Только: (а) проекция `controller.snapshots` в state для виджетов,
/// (б) проксирование user-intents в сервис. Никакого владения lifecycle'ом
/// очереди, подписок на БД или координации init — это всё живёт в
/// `TranscriptionQueueService`.
class TranscriptionQueueCubit extends BaseCubit<TranscriptionQueueState> {
  final TranscriptionQueueController _controller;
  late final StreamSubscription<TranscriptionQueueSnapshot> _snapshotSub;

  TranscriptionQueueCubit({required TranscriptionQueueController controller})
    : _controller = controller,
      super(TranscriptionQueueState(snapshot: controller.current)) {
    _snapshotSub = _controller.snapshots.listen(
      (snapshot) => safeEmit(TranscriptionQueueState(snapshot: snapshot)),
    );
  }

  Future<void> retry(String uid) => _controller.retry(uid);

  Future<void> cancel(String uid) => _controller.cancel(uid);

  Future<void> retryAll() => _controller.retryAll();

  Future<void> cancelAll() => _controller.cancelAll();

  Future<void> clearFailedAll() => _controller.clearFailedAll();

  Future<void> dismissFailed(String uid) => _controller.dismissFailed(uid);

  Future<void> retryBootstrap() => _controller.retryBootstrap();

  Future<void> resumeAfterInterruptedRun() =>
      _controller.resumeAfterInterruptedRun();

  void onResume() => _controller.resume();

  @override
  Future<void> close() async {
    await _snapshotSub.cancel();
    return super.close();
  }
}
