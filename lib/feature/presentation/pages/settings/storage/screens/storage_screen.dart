import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/common/utils/format_bytes.dart';
import 'package:voice_notes/core/adaptive/window/adaptive_content_width.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/status/status_state_widgets.dart';
import 'package:voice_notes/feature/domain/repositories/storage_stats_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/components/storage_folders_section.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/logic/storage_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/widgets/storage_overview_header.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

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
        onEmpty: (_, _) => const _EmptyState(),
        onSuccess: (context, state) {
          return RefreshableWrapper<StorageCubit>(
            child: AdaptiveContentWidth(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: StorageOverviewHeader(
                      overview: state.overview,
                      onClearAll: () => _onClearAllTap(context),
                    ),
                  ),
                  const StorageFoldersSection(),
                ],
              ),
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
