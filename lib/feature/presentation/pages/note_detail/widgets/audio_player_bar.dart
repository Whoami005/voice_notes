import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_playback_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/audio/audio_inline_player.dart';

/// Плеер для экрана детальной заметки.
///
/// Использует shared [AudioInlinePlayer] + speed picker.
class AudioPlayerBar extends StatefulWidget {
  final NoteAudioEntity audio;

  const AudioPlayerBar({required this.audio, super.key});

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotePlaybackCubit>().loadAudio(widget.audio);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.p8,
        horizontal: AppSizes.p12,
      ),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: BlocSelector<NotePlaybackCubit, NotePlaybackState, bool>(
        selector: (state) => state.isError,
        builder: (context, isError) =>
            isError ? const _ErrorState() : const _PlayerContent(),
      ),
    );
  }
}

class _PlayerContent extends StatelessWidget {
  const _PlayerContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<NotePlaybackCubit, NotePlaybackState>(
          buildWhen: (p, c) =>
              p.playbackStatus != c.playbackStatus ||
              p.position != c.position ||
              p.duration != c.duration,
          builder: (context, state) {
            final cubit = context.read<NotePlaybackCubit>();

            return AudioInlinePlayer(
              state: _mapToTrackState(state),
              onPlayPause: cubit.togglePlayPause,
              onSeek: cubit.seek,
              waveformData: cubit.waveformData,
            );
          },
        ),
        BlocSelector<NotePlaybackCubit, NotePlaybackState, (bool, double)>(
          selector: (state) => (state.isBuffering, state.speed),
          builder: (context, record) {
            final (isBuffering, speed) = record;
            final themeColors = context.themeColors;
            final textTheme = context.textTheme;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox.shrink(),
                if (isBuffering)
                  Text(
                    context.l10n.playerLoadingAudio,
                    style: textTheme.bodySmall?.copyWith(
                      color: themeColors.textTertiary,
                    ),
                  ),
                _SpeedPicker(speed: speed, enabled: !isBuffering),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SpeedPicker extends StatelessWidget {
  final double speed;
  final bool enabled;

  const _SpeedPicker({required this.speed, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return PopupMenuButton<double>(
      tooltip: l10n.playerSpeed,
      enabled: enabled,
      initialValue: speed,
      onSelected: (speed) =>
          context.read<NotePlaybackCubit>().setSpeed(speed),
      itemBuilder: (_) => [
        for (final speed in NotePlaybackCubit.availableSpeeds)
          PopupMenuItem(value: speed, child: Text(_formatSpeed(speed))),
      ],
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p8,
            vertical: AppSizes.p4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatSpeed(speed),
                style: textTheme.bodySmall?.copyWith(
                  color: themeColors.textSecondary,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: themeColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Row(
      spacing: AppSizes.p8,
      children: [
        Icon(Icons.error_outline_rounded, color: themeColors.error, size: 20),
        Expanded(
          child: Text(
            context.l10n.playerFileNotFound,
            style: textTheme.bodySmall?.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

TrackState _mapToTrackState(NotePlaybackState s) => TrackState(
  status: s.playbackStatus,
  position: s.position,
  duration: s.duration,
);

String _formatSpeed(double speed) {
  if (speed == speed.roundToDouble()) return '${speed.toInt()}x';
  return '${speed}x';
}
