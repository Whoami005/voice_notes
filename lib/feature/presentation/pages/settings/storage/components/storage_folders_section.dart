import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/folder_storage_stats.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/logic/storage_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/screens/folder_storage_screen.dart';
import 'package:voice_notes/feature/presentation/pages/settings/storage/widgets/folder_storage_tile.dart';

/// Секция со списком папок на главном экране хранилища: overline-заголовок
/// и декорированный sliver-список плиток. Подписывается на [StorageCubit].
class StorageFoldersSection extends StatelessWidget {
  const StorageFoldersSection({super.key});

  void _onFolderTap(BuildContext context, FolderStorageStats stats) {
    FolderStorageScreen.go(context, folderUid: stats.folder?.uid);
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    return BlocSelector<StorageCubit, StorageState, List<FolderStorageStats>>(
      selector: (state) => state.folders,
      builder: (context, folders) {
        return SliverPadding(
          padding: const EdgeInsets.only(
            top: AppSizes.p24,
            bottom: AppSizes.p32,
          ),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSizes.p8,
                    right: AppSizes.p8,
                    bottom: AppSizes.p8,
                  ),
                  child: Text(
                    l10n.storageFoldersSectionTitle,
                    style: AppTypography.overline.copyWith(
                      color: themeColors.textTertiary,
                    ),
                  ),
                ),
              ),
              DecoratedSliver(
                decoration: BoxDecoration(
                  color: themeColors.bgSecondary,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  border: Border.all(color: themeColors.borderPrimary),
                ),
                sliver: SliverList.separated(
                  itemCount: folders.length,
                  itemBuilder: (_, i) {
                    final folder = folders[i];

                    return FolderStorageTile(
                      stats: folder,
                      onTap: () => _onFolderTap(context, folder),
                    );
                  },
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    thickness: 1,
                    color: themeColors.borderPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
