part of 'transcription_queue_cubit.dart';

class TranscriptionQueueState extends Equatable {
  final TranscriptionQueueSnapshot snapshot;

  const TranscriptionQueueState({
    this.snapshot = const TranscriptionQueueSnapshot(),
  });

  QueueBootstrapState get bootstrapState => snapshot.bootstrapState;

  QueueRuntimeReason get runtimeReason => snapshot.runtimeReason;

  @override
  List<Object?> get props => [snapshot];
}
