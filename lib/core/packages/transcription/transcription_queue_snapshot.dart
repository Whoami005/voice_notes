import 'package:equatable/equatable.dart';

/// Снапшот in-memory очереди диспетчера. Источник истины по статусу
/// каждой заметки — БД, не снапшот.
class TranscriptionQueueSnapshot extends Equatable {
  /// FIFO-порядок ожидающих заметок.
  final List<String> queued;

  final String? processing;

  /// Circuit breaker: 3 подряд ошибки. Снимается явным retry() пользователя.
  final bool paused;

  const TranscriptionQueueSnapshot({
    this.queued = const [],
    this.processing,
    this.paused = false,
  });

  int get total => queued.length + (processing != null ? 1 : 0);

  @override
  List<Object?> get props => [queued, processing, paused];
}
