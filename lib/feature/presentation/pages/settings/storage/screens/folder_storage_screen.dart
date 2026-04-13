import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/common/utils/format_bytes.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/status/status_state_widgets.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/logic/folder_storage_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/widgets/note_audio_tile.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';

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
        repository: getIt<StorageStatsRepository>(),
        folderUid: folderUid,
      ),
      child: this,
    );
  }

  Future<void> _onClearFolderTap(BuildContext context) async {
    final cubit = context.read<FolderStorageCubit>();
    final state = cubit.state;
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.storageClearFolderConfirmTitle,
      message: l10n.storageClearFolderConfirmMessage(
        state.notes.length,
        BytesFormatter.format(state.totalBytes),
      ),
      confirmText: l10n.dialogClear,
      confirmColor: themeColors.error,
    );

    if ((confirmed ?? false) && context.mounted) {
      await cubit.deleteAllInFolder();
    }
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
          final folderName = state.folder?.name ?? l10n.storageWithoutFolder;
          final totalBytes = state.totalBytes;

          final bytesLabel = BytesFormatter.format(totalBytes);
          final countLabel = l10n.storageRecordingsCount(state.notes.length);

          return Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folderName,
                        style: textTheme.titleLarge?.copyWith(
                          color: themeColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacer.p4,
                      Text(
                        '$bytesLabel · $countLabel',
                        style: textTheme.bodyMedium?.copyWith(
                          color: themeColors.textSecondary,
                        ),
                      ),
                      AppSpacer.p16,
                      if (state.notes.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => _onClearFolderTap(context),
                            icon: Icon(
                              Icons.delete_sweep_outlined,
                              color: themeColors.error,
                            ),
                            label: Text(
                              l10n.storageClearFolderButton,
                              style: textTheme.labelLarge?.copyWith(
                                color: themeColors.error,
                              ),
                            ),
                          ),
                        ),
                      AppSpacer.p16,
                    ],
                  ),
                ),
                if (state.notes.isNotEmpty)
                  SliverList.separated(
                    itemCount: state.notes.length,
                    itemBuilder: (context, index) {
                      final item = state.notes[index];

                      return NoteAudioTile(
                        key: ValueKey('note_audio_${item.note.uuid}'),
                        stats: item,
                        onDismissRequest: () async {
                          await context
                              .read<FolderStorageCubit>()
                              .deleteNoteAudio(item.note.uuid);

                          return true;
                        },
                      );
                    },
                    separatorBuilder: (_, _) => AppSpacer.p8,
                  ),
                if (state.notes.isEmpty)
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
                  ),
                const SliverToBoxAdapter(child: AppSpacer.p32),
              ],
            ),
          );
        },
      ),
    );
  }
}
