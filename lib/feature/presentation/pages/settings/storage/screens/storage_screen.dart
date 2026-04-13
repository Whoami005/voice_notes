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
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/folder_storage_stats.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/logic/storage_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/screens/folder_storage_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/widgets/folder_storage_tile.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/widgets/storage_overview_header.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';

class StorageScreen extends StatelessWidget implements AppRouteWrapper {
  const StorageScreen({super.key});

  static void go(BuildContext context) {
    context.go(AppRoutes.settings.storage);
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => StorageCubit(repository: getIt<StorageStatsRepository>()),
      child: this,
    );
  }

  Future<void> _onClearAllTap(BuildContext context) async {
    final cubit = context.read<StorageCubit>();
    final state = cubit.state;
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.storageClearAllConfirmTitle,
      message: l10n.storageClearAllConfirmMessage(
        state.overview.totalCount,
        BytesFormatter.format(state.overview.totalBytes),
      ),
      confirmText: l10n.dialogClear,
      confirmColor: themeColors.error,
    );

    if ((confirmed ?? false) && context.mounted) {
      await cubit.deleteAllAudio();
    }
  }

  void _onFolderTap(BuildContext context, FolderStorageStats stats) {
    FolderStorageScreen.go(context, folderUid: stats.folder?.uid);
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      appBar: AppBar(
        title: Text(l10n.storageTitle),
        backgroundColor: themeColors.bgPrimary,
      ),
      body: StatusStateBody<StorageCubit, StorageState>(
        buildAlways: true,
        onEmpty: (context, state) => const _EmptyState(),
        onSuccess: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StorageOverviewHeader(
                        overview: state.overview,
                        onClearAll: () => _onClearAllTap(context),
                      ),
                      AppSpacer.p24,
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p8,
                        ),
                        child: Text(
                          l10n.storageFoldersSectionTitle,
                          style: AppTypography.overline.copyWith(
                            color: themeColors.textTertiary,
                          ),
                        ),
                      ),
                      AppSpacer.p8,
                    ],
                  ),
                ),
                DecoratedSliver(
                  decoration: BoxDecoration(
                    color: themeColors.bgSecondary,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(color: themeColors.borderPrimary),
                  ),
                  sliver: SliverList.separated(
                    itemCount: state.folders.length,
                    itemBuilder: (_, i) => FolderStorageTile(
                      stats: state.folders[i],
                      onTap: () => _onFolderTap(context, state.folders[i]),
                    ),
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 1,
                      color: themeColors.borderPrimary,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.audiotrack_outlined,
              size: 64,
              color: themeColors.textTertiary,
            ),
            AppSpacer.p16,
            Text(
              l10n.storageEmptyTitle,
              style: textTheme.titleMedium?.copyWith(
                color: themeColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacer.p8,
            Text(
              l10n.storageEmptySubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: themeColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
