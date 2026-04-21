import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
import 'package:voice_notes/feature/domain/enums/queue_runtime_reason.dart';

/// Фаза жизненного цикла сервиса очереди. `_recoverQueuedNotes` →
/// подписки → `ready`; любой сбой в bootstrap'е — `error(failure)`,
/// из которого UI может вызвать `retryBootstrap()`.
sealed class QueueBootstrapState extends Equatable {
  const QueueBootstrapState();

  bool get isNoteStarted => this is QueueBootstrapNotStarted;

  bool get isLoading => this is QueueBootstrapLoading;

  bool get isReady => this is QueueBootstrapReady;

  bool get isError => this is QueueBootstrapError;

  @override
  List<Object?> get props => [];
}

final class QueueBootstrapNotStarted extends QueueBootstrapState {
  const QueueBootstrapNotStarted();
}

final class QueueBootstrapLoading extends QueueBootstrapState {
  const QueueBootstrapLoading();
}

final class QueueBootstrapReady extends QueueBootstrapState {
  const QueueBootstrapReady();
}

final class QueueBootstrapError extends QueueBootstrapState {
  final AppFailure failure;

  const QueueBootstrapError(this.failure);

  @override
  List<Object?> get props => [failure];
}

/// Снапшот in-memory очереди диспетчера. Источник истины по статусу
/// каждой заметки — БД, не снапшот.
class TranscriptionQueueSnapshot extends Equatable {
  final QueueBootstrapState bootstrapState;

  /// FIFO-порядок ожидающих заметок.
  final List<String> queued;

  final String? processing;

  /// Заметки, для которых пользователь нажал cancel пока шла транскрибация.
  /// Нужно UI, чтобы сразу показывать "отменяется…" — сам статус в БД
  /// обновится только когда текущий ASR-пасс завершится.
  final Set<String> cancelRequested;

  /// Причина, по которой дренаж не идёт.
  /// - [QueueRuntimeReason.awaitingModel] — ждём выбор/загрузку ASR-модели.
  /// - [QueueRuntimeReason.breakerTripped] — circuit breaker (3 подряд
  ///   провала); снимается автоматически при появлении ASR-ready или
  ///   пользовательским retry().
  final QueueRuntimeReason runtimeReason;

  /// Прогресс текущей in-flight транскрибации. `null` для non-streaming
  /// моделей или до первого progress-события.
  final AsrTranscribeProgress? processingProgress;

  /// Зафиксированный на старте `_processOne` флаг: поддерживает ли
  /// текущая ASR-модель streaming. UI читает его для отображения
  /// determinate progress-бара и доступности cancel-кнопки. Не
  /// зависит от актуального состояния AsrCubit — unload/switch в
  /// середине задачи не ломает UI.
  final bool processingSupportsStreaming;

  const TranscriptionQueueSnapshot({
    this.bootstrapState = const QueueBootstrapNotStarted(),
    this.queued = const [],
    this.processing,
    this.cancelRequested = const {},
    this.runtimeReason = QueueRuntimeReason.none,
    this.processingProgress,
    this.processingSupportsStreaming = false,
  });

  int get total => queued.length + (processing != null ? 1 : 0);

  bool isCancelRequested(String uid) => cancelRequested.contains(uid);

  bool get paused => runtimeReason != QueueRuntimeReason.none;

  @override
  List<Object?> get props => [
    bootstrapState,
    queued,
    processing,
    cancelRequested,
    runtimeReason,
    processingProgress,
    processingSupportsStreaming,
  ];
}
