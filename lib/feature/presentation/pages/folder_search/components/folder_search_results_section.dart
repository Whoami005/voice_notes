import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/screens/folder_detail_screen.dart';
import 'package:voice_notes/feature/presentation/pages/folder_search/logic/folder_search_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/folder_card.dart';

const double _placeholderIconSize = 64;

/// Sliver that renders the right body for the folder search screen:
/// a hint when query is empty, a no-results view when nothing matches,
/// or a list of folders with the query highlighted in their names.
class FolderSearchResultsSection extends StatelessWidget {
  const FolderSearchResultsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FolderSearchCubit, FolderSearchState>(
      buildWhen: (p, c) =>
          p.query != c.query || p.filteredFolders != c.filteredFolders,
      builder: (context, state) {
        final folders = state.filteredFolders;
        if (folders.isEmpty) {
          return _NoResultsSliver(query: state.query);
        }

        return SliverPadding(
          padding: const EdgeInsets.only(
            top: AppSizes.p12,
            left: AppSizes.screenPadding,
            right: AppSizes.screenPadding,
            bottom: AppSizes.screenPadding,
          ),
          sliver: SliverList.separated(
            itemCount: folders.length,
            separatorBuilder: (_, _) => AppSpacer.p12,
            itemBuilder: (context, index) {
              final folder = folders[index];

              return FolderCard(
                folder: folder,
                highlightQuery: state.query,
                onTap: () =>
                    FolderDetailScreen.push(context, folderId: folder.uid),
              );
            },
          ),
        );
      },
    );
  }
}

class _NoResultsSliver extends StatelessWidget {
  final String query;

  const _NoResultsSliver({super.key, this.query = ''});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    final hasResults = query.trim().isNotEmpty;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: _placeholderIconSize,
                color: themeColors.textTertiary,
              ),
              AppSpacer.p16,
              Text(
                l10n.searchScreenNoResultsTitle,
                style: textTheme.titleMedium?.copyWith(
                  color: themeColors.textPrimary,
                ),
              ),
              if (hasResults) ...[
                AppSpacer.p8,
                Text(
                  l10n.searchScreenNoResultsHint(query.trim()),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: themeColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
