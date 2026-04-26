import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/presentation/widgets/highlighted_text.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class FolderCard extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? highlightQuery;

  const FolderCard({
    required this.folder,
    super.key,
    this.onTap,
    this.onLongPress,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: themeColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: themeColors.borderPrimary),
        ),
        child: Row(
          children: [
            _IconContainer(color: folder.color, icon: folder.iconData),
            AppSpacer.p14,
            Expanded(
              child: _TextContent(
                folder: folder,
                highlightQuery: highlightQuery,
              ),
            ),
            AppSpacer.p12,
            _CountPill(count: folder.notesCount),
          ],
        ),
      ),
    );
  }
}

class _IconContainer extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _IconContainer({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.avatarLarge,
      height: AppSizes.avatarLarge,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: AppSizes.iconLarge),
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

  const _CountPill({required this.count});

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
        color: themeColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        count.toString(),
        style: textTheme.labelMedium?.copyWith(
          color: themeColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
