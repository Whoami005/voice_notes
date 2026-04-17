part of 'transcription_queue_cubit.dart';

/// `initial` — `init()` ещё не завершил seed; публичные команды кубита
/// (`retry`/`cancel`) ранний-выход'ят. `ready` — seed выполнен, очередь
/// принимает команды (готовность ASR-модели — отдельная ось, читать из
/// `AsrCubit`).
enum QueueStatus {
  initial,
  ready;

  bool get isReady => this == QueueStatus.ready;

  bool get isInitial => this == QueueStatus.initial;
}

class TranscriptionQueueState extends Equatable {
  final QueueStatus status;
  final TranscriptionQueueSnapshot snapshot;

  const TranscriptionQueueState({
    this.status = QueueStatus.initial,
    this.snapshot = const TranscriptionQueueSnapshot(),
  });

  TranscriptionQueueState copyWith({
    QueueStatus? status,
    TranscriptionQueueSnapshot? snapshot,
  }) {
    return TranscriptionQueueState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
    );
  }

  @override
  List<Object?> get props => [status, snapshot];
}
