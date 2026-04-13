import 'package:flutter/material.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';

/// Play/pause кнопка с визуальными состояниями.
///
/// Размер иконки: 28px. Фон: accentPrimary с opacity.
/// active (playing) — более насыщенный фон.
class AudioPlayButton extends StatelessWidget {
  final PlaybackStatus status;
  final VoidCallback? onPressed;

  const AudioPlayButton({required this.status, this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final isPlaying = status.isPlaying;
    final isLoading = status.isLoading;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPlaying
              ? themeColors.accentPrimary.withValues(alpha: 0.2)
              : themeColors.accentPrimary.withValues(alpha: 0.1),
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: themeColors.accentPrimary,
                ),
              )
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: themeColors.accentPrimary,
                size: 18,
              ),
      ),
    );
  }
}
