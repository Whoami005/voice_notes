import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/feature/presentation/widgets/audio/audio_play_button.dart';
import 'package:voice_notes/feature/presentation/widgets/audio/audio_waveform_bar.dart';

/// Переиспользуемый inline-плеер.
///
/// Чистый презентационный виджет — получает всё через параметры.
/// Никакой бизнес-логики, подписок на стримы, initState.
class AudioInlinePlayer extends StatelessWidget {
  final TrackState state;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final List<double>? waveformData;

  const AudioInlinePlayer({
    required this.state,
    required this.onPlayPause,
    required this.onSeek,
    this.waveformData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p10,
        vertical: AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: themeColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: themeColors.borderSecondary),
      ),
      child: Row(
        spacing: AppSizes.p8,
        children: [
          AudioPlayButton(status: state.status, onPressed: onPlayPause),
          Expanded(
            child: AudioWaveformBar(
              position: state.position,
              duration: state.duration,
              onSeek: onSeek,
              waveformData: waveformData,
            ),
          ),
          Text(
            '${_formatDuration(state.position)} / ${_formatDuration(state.duration)}',
            style: textTheme.bodySmall?.copyWith(
              color: themeColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');

  return '$minutes:$seconds';
}
