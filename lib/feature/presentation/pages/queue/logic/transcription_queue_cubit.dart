import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/state/core/base_cubit.dart';

part 'transcription_queue_state.dart';

/// UI-адаптер очереди транскрибации.
///
/// Только: (а) проекция `service.snapshots` в state для виджетов,
/// (б) проксирование user-intents в сервис. Никакого владения lifecycle'ом
/// очереди, подписок на БД или координации init — это всё живёт в
/// `TranscriptionQueueService`.
class TranscriptionQueueCubit extends BaseCubit<TranscriptionQueueState> {
  final TranscriptionQueueService _service;
  late final StreamSubscription<TranscriptionQueueSnapshot> _snapshotSub;

  TranscriptionQueueCubit({required TranscriptionQueueService service})
    : _service = service,
      super(TranscriptionQueueState(snapshot: service.current)) {
    _snapshotSub = _service.snapshots.listen(
      (snapshot) => safeEmit(TranscriptionQueueState(snapshot: snapshot)),
    );
  }

  Future<void> retry(String uid) => _service.retry(uid);

  Future<void> cancel(String uid) => _service.cancel(uid);

  Future<void> retryAll() => _service.retryAll();

  Future<void> cancelAll() => _service.cancelAll();

  Future<void> clearFailedAll() => _service.clearFailedAll();

  Future<void> dismissFailed(String uid) => _service.dismissFailed(uid);

  Future<void> retryBootstrap() => _service.retryBootstrap();

  void onResume() => _service.resume();

  @override
  Future<void> close() async {
    await _snapshotSub.cancel();
    return super.close();
  }
}
