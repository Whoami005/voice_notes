import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/theme/app_colors.dart';

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
          color: AppColors.transparent,
          child: Container(
            key: const Key('global-playback-mini-player'),
            margin: const EdgeInsets.only(
              top: AppSizes.p8,
              left: AppSizes.p10,
              right: AppSizes.p10,
            ),
            decoration: BoxDecoration(
              color: themeColors.workspacePane,
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
              border: Border.all(color: themeColors.workspaceBorderSoft),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
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
                        vertical: AppSizes.p10,
                        horizontal: AppSizes.p14,
                      ),
                      child: Row(
                        spacing: AppSizes.p12,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.p8),
                            decoration: BoxDecoration(
                              color: themeColors.workspaceSelectionSoft,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium,
                              ),
                            ),
                            child: Icon(
                              Icons.graphic_eq_rounded,
                              color: themeColors.accentPrimary,
                              size: AppSizes.iconMedium,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: themeColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSizes.p4,
                    right: AppSizes.p8,
                  ),
                  child: IconButton(
                    tooltip: context.l10n.playerPause,
                    style: IconButton.styleFrom(
                      backgroundColor: themeColors.workspaceSelectionSoft,
                      foregroundColor: themeColors.accentPrimary,
                    ),
                    onPressed: _controller.pause,
                    icon: const Icon(Icons.pause_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
