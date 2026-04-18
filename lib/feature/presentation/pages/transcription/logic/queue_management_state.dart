part of 'queue_management_cubit.dart';

class QueueManagementState extends Equatable {
  final List<NoteEntity> failed;
  final List<NoteEntity> cancelled;

  const QueueManagementState({
    this.failed = const [],
    this.cancelled = const [],
  });

  bool get hasFailed => failed.isNotEmpty;

  bool get hasCancelled => cancelled.isNotEmpty;

  QueueManagementState copyWith({
    List<NoteEntity>? failed,
    List<NoteEntity>? cancelled,
  }) {
    return QueueManagementState(
      failed: failed ?? this.failed,
      cancelled: cancelled ?? this.cancelled,
    );
  }

  @override
  List<Object?> get props => [failed, cancelled];
}
