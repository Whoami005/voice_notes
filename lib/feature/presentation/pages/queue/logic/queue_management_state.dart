part of 'queue_management_cubit.dart';

class QueueManagementState extends Equatable {
  final QueueBootstrapState bootstrapState;
  final QueueRuntimeReason runtimeReason;
  final NoteEntity? processing;
  final List<NoteEntity> queued;
  final List<NoteEntity> failed;
  final List<NoteEntity> cancelled;
  final Set<String> cancelRequested;

  const QueueManagementState({
    this.bootstrapState = const QueueBootstrapNotStarted(),
    this.runtimeReason = QueueRuntimeReason.none,
    this.processing,
    this.queued = const [],
    this.failed = const [],
    this.cancelled = const [],
    this.cancelRequested = const {},
  });

  bool get hasProcessing => processing != null;

  bool get hasQueued => queued.isNotEmpty;

  bool get hasFailed => failed.isNotEmpty;

  bool get hasCancelled => cancelled.isNotEmpty;

  bool isCancelRequested(String uid) => cancelRequested.contains(uid);

  QueueManagementState copyWith({
    QueueBootstrapState? bootstrapState,
    QueueRuntimeReason? runtimeReason,
    NoteEntity? processing,
    bool clearProcessing = false,
    List<NoteEntity>? queued,
    List<NoteEntity>? failed,
    List<NoteEntity>? cancelled,
    Set<String>? cancelRequested,
  }) {
    return QueueManagementState(
      bootstrapState: bootstrapState ?? this.bootstrapState,
      runtimeReason: runtimeReason ?? this.runtimeReason,
      processing: clearProcessing ? null : (processing ?? this.processing),
      queued: queued ?? this.queued,
      failed: failed ?? this.failed,
      cancelled: cancelled ?? this.cancelled,
      cancelRequested: cancelRequested ?? this.cancelRequested,
    );
  }

  @override
  List<Object?> get props => [
    bootstrapState,
    runtimeReason,
    processing,
    queued,
    failed,
    cancelled,
    cancelRequested,
  ];
}
