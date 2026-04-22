import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';

class GlobalPlaybackMiniPlayer extends StatelessWidget {
  final AudioPlaybackController controller;

  const GlobalPlaybackMiniPlayer({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackSessionState>(
      stream: controller.sessionStream,
      initialData: controller.session,
      builder: (context, snapshot) {
        final session = snapshot.data ?? controller.session;
        if (!session.isVisible) return const SizedBox.shrink();

        final themeColors = context.themeColors;
        final textTheme = context.textTheme;
        final title = (session.title ?? '').trim();
        final displayTitle = title.isEmpty ? '---' : title;

        return Material(
          color: themeColors.bgPrimary,
          child: Container(
            key: const Key('global-playback-mini-player'),
            decoration: BoxDecoration(
              color: themeColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              border: Border.all(color: themeColors.borderPrimary),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                    onTap: session.folderId == null
                        ? null
                        : () => context.go(
                            AppRoutes.folders.noteDetail(
                              folderId: session.folderId!,
                              noteId: session.trackId!,
                            ),
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p16,
                        vertical: AppSizes.p12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: themeColors.accentPrimary,
                          ),
                          const SizedBox(width: AppSizes.p12),
                          Expanded(
                            child: Text(
                              displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: themeColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.playerPause,
                  onPressed: controller.pause,
                  icon: const Icon(Icons.pause_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
