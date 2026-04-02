import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class FolderCard extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FolderCard({
    required this.folder,
    super.key,
    this.onTap,
    this.onLongPress,
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
              child: _TextContent(folder: folder),
            ),
            Icon(
              Icons.chevron_right,
              size: AppSizes.iconMedium,
              color: themeColors.textTertiary,
            ),
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

  const _TextContent({required this.folder});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          folder.name,
          style: textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        AppSpacer.p2,
        Text(
          _buildSubtitle(l10n, localeCode),
          style: textTheme.labelMedium?.copyWith(
            color: themeColors.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _buildSubtitle(AppLocalizations l10n, String localeCode) {
    final count = folder.notesCount;
    final noteWord = l10n.folderCardNotesCount(count);
    final timeAgo = _formatTimeAgo(folder.updatedAt, l10n, localeCode);
    return '$noteWord \u2022 $timeAgo';
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
