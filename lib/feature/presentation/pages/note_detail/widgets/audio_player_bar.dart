import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_playback_cubit.dart';

/// Компактный плеер для воспроизведения оригинальной записи заметки.
///
/// Рендерится сверху `NoteDetailBody` если `note.audio != null`.
/// Сам управляет загрузкой через [NotePlaybackCubit.loadAudio] на mount.
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
    // Запуск загрузки в отдельном микротаске, чтобы не блокировать build.
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
        const Row(
          spacing: AppSizes.p8,
          children: [
            _PlayPauseButton(),
            Expanded(child: _SeekBarSection()),
          ],
        ),
        BlocSelector<NotePlaybackCubit, NotePlaybackState, bool>(
          selector: (state) => state.isBuffering,
          builder: (context, isBuffering) {
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
                _SpeedPicker(enabled: !isBuffering),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Slider + duration label. Единственная часть, ребилдящаяся на каждый тик
/// позиции (~100-200ms). Остальные виджеты плеера не перестраиваются.
///
/// Во время drag слайдера позиция отображается из локального стейта,
/// чтобы stream-тики плеера не дёргали ползунок.
class _SeekBarSection extends StatefulWidget {
  const _SeekBarSection();

  @override
  State<_SeekBarSection> createState() => _SeekBarSectionState();
}

class _SeekBarSectionState extends State<_SeekBarSection> {
  bool _isDragging = false;
  double _dragValue = 0;

  double _displayValue(double streamValue) =>
      _isDragging ? _dragValue : streamValue;

  Duration _displayPosition(Duration streamPosition) =>
      _isDragging ? Duration(milliseconds: _dragValue.round()) : streamPosition;

  void _onDragStart(double value) => setState(() {
    _isDragging = true;
    _dragValue = value;
  });

  void _onDragUpdate(double value) => setState(() => _dragValue = value);

  void _onDragEnd(BuildContext context, double value) {
    context.read<NotePlaybackCubit>().seek(
      Duration(milliseconds: value.round()),
    );

    setState(() => _isDragging = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      NotePlaybackCubit,
      NotePlaybackState,
      (Duration, Duration)
    >(
      selector: (state) => (state.position, state.duration),
      builder: (context, record) {
        final (position, duration) = record;
        final themeColors = context.themeColors;
        final textTheme = context.textTheme;

        final sliderMax = duration.inMilliseconds.toDouble();
        final sliderValue = position.inMilliseconds
            .clamp(0, duration.inMilliseconds)
            .toDouble();
        final isInteractive = sliderMax > 0;

        return Row(
          spacing: AppSizes.p8,
          children: [
            Expanded(
              child: Slider(
                value: _displayValue(sliderValue),
                max: isInteractive ? sliderMax : 1,
                onChangeStart: isInteractive ? _onDragStart : null,
                onChanged: isInteractive ? _onDragUpdate : null,
                onChangeEnd: isInteractive
                    ? (v) => _onDragEnd(context, v)
                    : null,
                activeColor: themeColors.accentPrimary,
                inactiveColor: themeColors.borderSecondary,
              ),
            ),
            Text(
              '${_formatDuration(_displayPosition(position))} / ${_formatDuration(duration)}',
              style: textTheme.bodySmall?.copyWith(
                color: themeColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NotePlaybackCubit, NotePlaybackState, bool>(
      selector: (state) => state.isPlaying,
      builder: (context, isPlaying) {
        final themeColors = context.themeColors;
        final l10n = context.l10n;

        return IconButton(
          tooltip: isPlaying ? l10n.playerPause : l10n.playerPlay,
          onPressed: context.read<NotePlaybackCubit>().togglePlayPause,
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: themeColors.accentPrimary,
            size: 32,
          ),
        );
      },
    );
  }
}

class _SpeedPicker extends StatelessWidget {
  final bool enabled;

  const _SpeedPicker({this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NotePlaybackCubit, NotePlaybackState, double>(
      selector: (state) => state.speed,
      builder: (context, speed) {
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
      },
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

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');

  return '$minutes:$seconds';
}

String _formatSpeed(double speed) {
  if (speed == speed.roundToDouble()) return '${speed.toInt()}x';

  return '${speed}x';
}
