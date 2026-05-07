import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_playback_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/date_separator.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/note_bubble/note_bubble.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/screens/note_detail_screen.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/conditional/conditional_wrapper.dart';
import 'package:voice_notes/feature/presentation/widgets/lists/bloc_grouped_sliver_list.dart';
import 'package:voice_notes/feature/presentation/widgets/visibility/app_visibility_detector.dart';

class NotesListSection extends StatelessWidget {
  const NotesListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocGroupedSliverList<
      FolderDetailCubit,
      AsyncState<FolderDetailData>,
      NoteEntity
    >(
      selector: (state) => state.requireData.groupedNotes(
        todayLabel: l10n.dateToday,
        yesterdayLabel: l10n.dateYesterday,
        localeCode: localeCode,
      ),
      buildWhen: (p, c) => p.requireData.notes != c.requireData.notes,
      padding: const EdgeInsets.only(
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        top: AppSizes.p8,
        bottom: AppSizes.listBottomSafeForFab,
      ),
      headerBuilder: (context, label) => DateSeparator(date: label),
      itemBuilder: (context, note, _) => _NoteListItem(note: note),
    );
  }
}

class _NoteListItem extends StatelessWidget {
  final NoteEntity note;

  const _NoteListItem({required this.note, super.key});

  @override
  Widget build(BuildContext context) {
    final queueCubit = context.read<TranscriptionQueueCubit>();
    final playbackCubit = context.read<FolderPlaybackCubit>();

    return BlocSelector<
      FolderPlaybackCubit,
      FolderPlaybackState,
      (bool, TrackState, List<double>?)
    >(
      selector: (state) => (
        state.isPlaying(note.uuid),
        state.trackState(note.uuid),
        state.waveform(note.uuid),
      ),
      builder: (context, record) {
        final (isPlaying, trackState, waveformData) = record;
        final audioExists = note.origin.audio != null;

        return ConditionalWrapper(
          condition: audioExists && waveformData == null,
          onAddWrapper: (child) {
            return AppVisibilityDetector(
              detectorKey: ValueKey('note_waveform_${note.uuid}'),
              onVisibilityChanged: (info) {
                if (!info.isVisible) return;
                unawaited(playbackCubit.ensureWaveformLoaded(note));
              },
              child: child,
            );
          },
          child: NoteBubble(
            note: note,
            isPlaying: isPlaying,
            trackState: audioExists ? trackState : null,
            waveformData: audioExists ? waveformData : null,
            margin: const EdgeInsets.only(bottom: AppSizes.p12),
            onPlayPause: audioExists
                ? () => playbackCubit.togglePlayPause(note.uuid)
                : null,
            onSeek: audioExists
                ? (pos) => playbackCubit.seek(note.uuid, pos)
                : null,
            onTap: () {
              final folderId = context.read<FolderDetailCubit>().folderId;
              NoteDetailScreen.go(
                context,
                folderId: folderId,
                noteId: note.uuid,
              );
            },
            onRetry: (note.isFailed || note.isCancelled)
                ? () => queueCubit.retry(note.uuid)
                : null,
            onCancel: (note.isQueued || note.isTranscribing)
                ? () => queueCubit.cancel(note.uuid)
                : null,
            onCopy: () => Clipboard.setData(ClipboardData(text: note.text)),
            onShare: () {},
          ),
        );
      },
    );
  }
}
