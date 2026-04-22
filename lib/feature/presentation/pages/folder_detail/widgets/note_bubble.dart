import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/transcription_failure_reason_l10n.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/transcription/asr_rtf_estimates.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/audio/audio_inline_player.dart';
import 'package:voice_notes/feature/presentation/widgets/chips/tag_chip.dart';

class NoteBubble extends StatelessWidget {
  final NoteEntity note;
  final bool isPlaying;
  final TrackState? trackState;
  final List<double>? waveformData;
  final VoidCallback? onPlayPause;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  final EdgeInsetsGeometry? margin;

  const NoteBubble({
    required this.note,
    this.isPlaying = false,
    this.trackState,
    this.waveformData,
    this.onPlayPause,
    this.onSeek,
    this.onTap,
    this.onCopy,
    this.onShare,
    this.onRetry,
    this.onCancel,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final screenWidth = context.screenSize.width;

    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: note.isCompleted ? onTap : null,
        child: Container(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p14,
          ),
          margin: margin,
          decoration: BoxDecoration(
            color: themeColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppSizes.bubbleRadius),
            border: Border.all(
              color: isPlaying
                  ? themeColors.accentPrimary.withValues(alpha: 0.33)
                  : themeColors.borderPrimary,
            ),
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: themeColors.accentPrimary.withValues(alpha: 0.07),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Column(
            spacing: AppSizes.p8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.audio != null && trackState != null)
                AudioInlinePlayer(
                  state: trackState!,
                  onPlayPause: onPlayPause ?? () {},
                  onSeek: onSeek ?? (_) {},
                  waveformData: waveformData,
                ),
              _StatusContent(note: note, onRetry: onRetry, onCancel: onCancel),
              if (note.isCompleted && note.tags.isNotEmpty)
                Wrap(
                  spacing: AppSizes.p6,
                  runSpacing: AppSizes.p6,
                  children: List.generate(
                    note.tags.length,
                    (index) => TagChip(label: note.tags[index].name),
                  ),
                ),
              _MetaInfo(note: note),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusContent extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const _StatusContent({
    required this.note,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (note.isCompleted) {
      final textTheme = context.textTheme;

      return Text(
        note.text,
        style: textTheme.bodyMedium?.copyWith(height: 1.5),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      );
    }

    final themeColors = context.themeColors;
    final l10n = context.l10n;

    final cancel = onCancel;
    final cancelAction = cancel == null
        ? null
        : _StatusAction(
            icon: Icons.close,
            label: l10n.noteActionCancel,
            color: themeColors.textSecondary,
            onPressed: cancel,
          );

    if (note.isQueued) {
      return _StatusLine(
        icon: Icons.schedule_outlined,
        label: l10n.noteStatusQueued,
        color: themeColors.textSecondary,
        italic: true,
        action: cancelAction,
      );
    }

    if (note.isTranscribing) {
      return BlocSelector<
        TranscriptionQueueCubit,
        TranscriptionQueueState,
        _TranscribingViewData
      >(
        selector: (state) =>
            _TranscribingViewData.fromSnapshot(state.snapshot, note.uuid),
        builder: (context, data) {
          if (data.supportsInteractiveProgress) {
            return _InteractiveTranscribingRow(
              progress: data.progress,
              cancelAction: data.supportsCancellation ? cancelAction : null,
            );
          }

          return _StatusLine(
            showSpinner: true,
            label: _transcribingLabel(context),
            color: themeColors.textSecondary,
            italic: true,
            // Для не-streaming моделей cancel-кнопка скрывается в
            // процессе transcribing — offline decode прервать нельзя.
            // Пользователь по-прежнему может нажать Cancel, пока заметка
            // ещё в очереди (`isQueued`).
          );
        },
      );
    }

    final retry = onRetry;
    final retryAction = retry == null
        ? null
        : _StatusAction(
            icon: Icons.refresh,
            label: l10n.noteActionRetry,
            color: themeColors.accentPrimary,
            onPressed: retry,
          );

    if (note.isCancelled) {
      return _StatusLine(
        icon: Icons.block_outlined,
        label: l10n.noteStatusCancelled,
        color: themeColors.textTertiary,
        action: retryAction,
      );
    }

    final reason = note.failureReason ?? TranscriptionFailureReason.unknown;
    return _StatusLine(
      icon: Icons.error_outline,
      label: reason.title(l10n),
      color: themeColors.error,
      action: reason.isPermanent ? null : retryAction,
    );
  }

  String _transcribingLabel(BuildContext context) {
    final l10n = context.l10n;
    final asrState = context.read<AsrCubit>().state;
    final modelType = asrState.model?.modelType;
    if (modelType == null) return l10n.noteStatusTranscribing;

    final eta = AsrRtfEstimates.estimate(
      note.duration,
      modelId: asrState.model?.uuid,
      modelType: modelType,
    );
    return l10n.noteStatusTranscribingEta(eta.inSeconds);
  }
}

/// Строка статуса с иконкой/спиннером, подписью и опциональной кнопкой.
class _StatusLine extends StatelessWidget {
  final IconData? icon;
  final bool showSpinner;
  final String label;
  final Color color;
  final bool italic;
  final _StatusAction? action;

  const _StatusLine({
    required this.label,
    required this.color,
    this.icon,
    this.showSpinner = false,
    this.italic = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final action = this.action;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: AppSizes.p8,
          children: [
            if (showSpinner)
              SizedBox(
                width: AppSizes.p16,
                height: AppSizes.p16,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.strokeThin,
                  color: color,
                ),
              )
            else if (icon != null)
              Icon(icon, size: AppSizes.p16, color: color),
            Flexible(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontStyle: italic ? FontStyle.italic : null,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        if (action != null) ...[
          AppSpacer.p8,
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon, size: AppSizes.p16),
              label: Text(action.label),
              style: TextButton.styleFrom(
                foregroundColor: action.color,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p12,
                  vertical: AppSizes.p6,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Снимок snapshot'а очереди для конкретной транскрибируемой заметки.
///
/// Изолирует UI-слой от формы `TranscriptionQueueSnapshot`. Если заметка
/// сейчас не `processing` в очереди — возвращаем fallback (нет progress'а,
/// non-streaming), чтобы UI вёл себя как в легаси-сценарии.
class _TranscribingViewData {
  final bool supportsInteractiveProgress;
  final bool supportsCancellation;
  final AsrTranscribeProgress? progress;

  const _TranscribingViewData({
    required this.supportsInteractiveProgress,
    required this.supportsCancellation,
    required this.progress,
  });

  factory _TranscribingViewData.fromSnapshot(
    TranscriptionQueueSnapshot snapshot,
    String noteUid,
  ) {
    if (snapshot.processing != noteUid) {
      return const _TranscribingViewData(
        supportsInteractiveProgress: false,
        supportsCancellation: false,
        progress: null,
      );
    }

    return _TranscribingViewData(
      supportsInteractiveProgress:
          snapshot.processingSupportsInteractiveProgress,
      supportsCancellation: snapshot.processingSupportsCancellation,
      progress: snapshot.processingProgress,
    );
  }
}

/// Interactive-стратегия: determinate-прогресс + `Расшифровка: N%` + cancel.
class _InteractiveTranscribingRow extends StatelessWidget {
  final AsrTranscribeProgress? progress;
  final _StatusAction? cancelAction;

  const _InteractiveTranscribingRow({
    required this.progress,
    required this.cancelAction,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final progressValue = progress?.progress;
    final percentLabel = progress != null
        ? l10n.noteStatusTranscribingProgress(progress!.percent)
        : l10n.noteStatusTranscribing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSizes.p8,
      children: [
        Text(
          percentLabel,
          style: textTheme.bodyMedium?.copyWith(
            color: themeColors.textSecondary,
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
        LinearProgressIndicator(
          key: const Key('note-bubble-progress-bar'),
          value: progressValue,
          minHeight: AppSizes.strokeMedium,
          color: themeColors.accentPrimary,
          backgroundColor: themeColors.bgPrimary,
        ),
        if (cancelAction != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('note-bubble-cancel-button'),
              onPressed: cancelAction!.onPressed,
              icon: Icon(cancelAction!.icon, size: AppSizes.p16),
              label: Text(cancelAction!.label),
              style: TextButton.styleFrom(
                foregroundColor: cancelAction!.color,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p12,
                  vertical: AppSizes.p6,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _StatusAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
}

class _MetaInfo extends StatelessWidget {
  final NoteEntity note;

  const _MetaInfo({required this.note});

  @override
  Widget build(BuildContext context) {
    final metaStyle = context.textTheme.labelSmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_formatTime(note.createdAt), style: metaStyle),
        const _Dot(),
        Text(_formatDuration(note.duration), style: metaStyle),
        if (note.language.isNotEmpty) ...[
          const _Dot(),
          Text(note.language, style: metaStyle),
        ],
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    final color = context.themeColors.textTertiary;

    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
