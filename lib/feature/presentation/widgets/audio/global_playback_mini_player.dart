import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';

class GlobalPlaybackMiniPlayer extends StatefulWidget {
  final AudioPlaybackController? controller;

  const GlobalPlaybackMiniPlayer({this.controller, super.key});

  @override
  State<GlobalPlaybackMiniPlayer> createState() =>
      _GlobalPlaybackMiniPlayerState();
}

class _GlobalPlaybackMiniPlayerState extends State<GlobalPlaybackMiniPlayer> {
  late final AudioPlaybackController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? getIt<AudioPlaybackController>();
  }

  String _getDisplayTitle(PlaybackSessionState session) {
    final title = (session.title ?? '').trim();
    if (title.isNotEmpty) return title;

    final trackId = (session.trackId ?? '').trim();
    if (trackId.isEmpty) return '---';

    final normalizedTrackId = trackId.replaceAll('-', '').toUpperCase();
    final shortPart = normalizedTrackId.length <= 8
        ? normalizedTrackId
        : normalizedTrackId.substring(0, 8);

    return 'VN-$shortPart';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackSessionState>(
      stream: _controller.sessionStream,
      initialData: _controller.session,
      builder: (context, snapshot) {
        final session = snapshot.data ?? _controller.session;
        if (!session.isVisible) return const SizedBox.shrink();

        final themeColors = context.themeColors;
        final textTheme = context.textTheme;
        final displayTitle = _getDisplayTitle(session);

        return Material(
          color: themeColors.bgPrimary,
          child: Container(
            key: const Key('global-playback-mini-player'),
            margin: const EdgeInsets.only(
              bottom: AppSizes.p8,
              left: AppSizes.p10,
              right: AppSizes.p10,
            ),
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
                        vertical: AppSizes.p12,
                        horizontal: AppSizes.p16,
                      ),
                      child: Row(
                        spacing: AppSizes.p12,
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: themeColors.accentPrimary,
                          ),
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
                  onPressed: _controller.pause,
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
