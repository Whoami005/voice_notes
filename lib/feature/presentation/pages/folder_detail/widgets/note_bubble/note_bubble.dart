import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/common/utils/date_time_formatter.dart';
import 'package:voice_notes/common/utils/duration_formatter.dart';
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

part 'note_bubble_meta_info.dart';
part 'note_bubble_status_action.dart';
part 'note_bubble_status_content.dart';
part 'note_bubble_status_line.dart';
part 'note_bubble_transcribing_content.dart';

const _statusContentAnimationDuration = Duration(milliseconds: 180);
const _previewFadeDuration = Duration(milliseconds: 160);

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
        onTap: onTap,
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
              if (note.origin.audio != null && trackState != null)
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
