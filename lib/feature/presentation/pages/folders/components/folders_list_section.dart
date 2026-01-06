import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/state/state.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/folder_card.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/folders_section_header.dart';
import 'package:voice_notes/feature/presentation/widgets/lists/bloc_sliver_list_section.dart';

/// Sliver section displaying the list of folders with a header.
///
/// Uses [BlocSliverListSection] internally to reactively rebuild
/// when the folders state changes.
class FoldersListSection extends StatelessWidget {
  final void Function(FolderEntity folder) onFolderTap;
  final void Function(FolderEntity folder) onFolderLongPress;

  const FoldersListSection({
    required this.onFolderTap,
    required this.onFolderLongPress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSliverListSection<
      FoldersCubit,
      BaseState<FoldersState>,
      FolderEntity
    >(
      selector: (state) => state.requireData.folders,
      padding: const EdgeInsets.only(
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        bottom: AppSizes.screenPadding,
      ),
      headerBuilder: (context, items) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.p12),
        child: FoldersSectionHeader(title: 'Папки', count: items.length),
      ),
      separatorBuilder: (_, _) => AppSpacer.p12,
      itemBuilder: (context, folder, index) => FolderCard(
        folder: folder,
        onTap: () => onFolderTap(folder),
        onLongPress: () => onFolderLongPress(folder),
      ),
    );
  }
}
