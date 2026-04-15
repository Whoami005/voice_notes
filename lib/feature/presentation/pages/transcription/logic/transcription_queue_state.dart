part of 'transcription_queue_cubit.dart';

enum QueueStatus { initial, waitingForModel, initializing, ready }

class TranscriptionQueueState extends Equatable {
  final QueueStatus status;
  final TranscriptionQueueSnapshot snapshot;

  const TranscriptionQueueState({
    this.status = QueueStatus.initial,
    this.snapshot = const TranscriptionQueueSnapshot(),
  });

  bool get isInitializing => status == QueueStatus.initializing;

  bool get isReady => status == QueueStatus.ready;

  bool get isWaitingForModel => status == QueueStatus.waitingForModel;

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
