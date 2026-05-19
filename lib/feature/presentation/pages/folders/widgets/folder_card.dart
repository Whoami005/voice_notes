import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/presentation/widgets/folder_icon_badge.dart';
import 'package:voice_notes/feature/presentation/widgets/highlighted_text.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class FolderCard extends StatelessWidget {
  final FolderEntity folder;
  final bool useWorkspaceStyle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? highlightQuery;

  const FolderCard({
    required this.folder,
    this.useWorkspaceStyle = false,
    super.key,
    this.onTap,
    this.onLongPress,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final backgroundColor = useWorkspaceStyle
        ? themeColors.workspaceInset
        : themeColors.bgSecondary;
    final borderColor = useWorkspaceStyle
        ? themeColors.workspaceBorderSoft
        : themeColors.borderPrimary;
    final borderRadius = BorderRadius.circular(
      useWorkspaceStyle ? AppSizes.radiusLarge : AppSizes.cardRadius,
    );
    final contentPadding = useWorkspaceStyle
        ? AppSizes.p14
        : AppSizes.cardPadding;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: EdgeInsets.all(contentPadding),
            child: Row(
              spacing: AppSizes.p14,
              children: [
                FolderIconBadge(
                  icon: folder.icon,
                  color: folder.color,
                  size: AppSizes.avatarLarge,
                  iconSize: AppSizes.iconLarge,
                  borderRadius: AppSizes.p14,
                ),
                Expanded(
                  child: _TextContent(
                    folder: folder,
                    highlightQuery: highlightQuery,
                  ),
                ),
                _CountPill(
                  count: folder.notesCount,
                  useWorkspaceStyle: useWorkspaceStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  final FolderEntity folder;
  final String? highlightQuery;

  const _TextContent({required this.folder, this.highlightQuery});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    final query = highlightQuery ?? '';
    final description = folder.description?.trim() ?? '';
    final hasDescription = description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HighlightedText(
          text: folder.name,
          query: query,
          style: textTheme.titleMedium,
          maxLines: 1,
        ),
        if (hasDescription) ...[
          AppSpacer.p2,
          HighlightedText(
            text: description,
            query: query,
            style: textTheme.bodySmall?.copyWith(
              color: themeColors.textSecondary,
            ),
            maxLines: 1,
          ),
        ],
        AppSpacer.p2,
        Text(
          _formatTimeAgo(folder.updatedAt, l10n, localeCode),
          style: textTheme.labelMedium?.copyWith(
            color: themeColors.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatTimeAgo(
    DateTime dateTime,
    AppLocalizations l10n,
    String localeCode,
  ) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return l10n.folderCardMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.folderCardHoursAgo(difference.inHours);
    } else if (difference.inDays == 1) {
      return l10n.folderCardYesterday;
    } else if (difference.inDays < 7) {
      return l10n.folderCardDaysAgo(difference.inDays);
    } else {
      return DateFormat('d MMM', localeCode).format(dateTime);
    }
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  final bool useWorkspaceStyle;

  const _CountPill({required this.count, required this.useWorkspaceStyle});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: useWorkspaceStyle
            ? themeColors.workspaceSelectionSoft
            : themeColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        count.toString(),
        style: textTheme.labelMedium?.copyWith(
          color: useWorkspaceStyle
              ? themeColors.accentPrimary
              : themeColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
