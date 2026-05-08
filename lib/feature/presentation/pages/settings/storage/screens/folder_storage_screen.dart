import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/adaptive/window/adaptive_content_width.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/status/status_state_widgets.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/components/folder_storage_header.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/logic/folder_storage_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/widgets/note_audio_tile.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

class FolderStorageScreen extends StatelessWidget implements AppRouteWrapper {
  /// `null` — группа «Без папки», иначе uid конкретной папки.
  final String? folderUid;

  const FolderStorageScreen({required this.folderUid, super.key});

  static void go(BuildContext context, {String? folderUid}) {
    context.go(AppRoutes.settings.folderStorage(folderUid ?? 'none'));
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => FolderStorageCubit(
        folderUid: folderUid,
        repository: getIt<StorageStatsRepository>(),
      ),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      appBar: AppBar(backgroundColor: themeColors.bgPrimary),
      body: StatusStateBody<FolderStorageCubit, FolderStorageState>(
        buildAlways: true,
        onSuccess: (context, state) {
          return RefreshableWrapper<FolderStorageCubit>(
            child: AdaptiveContentWidth(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: FolderStorageHeader()),
                  const SliverToBoxAdapter(child: AppSpacer.p16),
                  if (state.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.p40,
                        ),
                        child: Center(
                          child: Text(
                            l10n.storageEmptyTitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: themeColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList.separated(
                      itemCount: state.notes.length,
                      itemBuilder: (context, index) {
                        final item = state.notes[index];

                        return NoteAudioTile(
                          key: ValueKey('note_audio_${item.note.uuid}'),
                          stats: item,
                          onDismissRequest: () => context
                              .read<FolderStorageCubit>()
                              .deleteNoteAudio(item.note.uuid),
                        );
                      },
                      separatorBuilder: (_, _) => AppSpacer.p8,
                    ),
                  const SliverToBoxAdapter(child: AppSpacer.p32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
