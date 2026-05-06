import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/presentation/widgets/folder_icon_badge.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class FolderAboutCard extends StatelessWidget {
  final FolderEntity folder;

  const FolderAboutCard({required this.folder, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FolderIconBadge(
            icon: folder.icon,
            color: folder.color,
            size: AppSizes.avatarSmall,
            iconSize: AppSizes.iconLarge,
            borderRadius: AppSizes.radiusMedium,
          ),
          AppSpacer.p12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.folderAboutLabel.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: themeColors.textTertiary,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppSpacer.p4,
                Text(
                  folder.description!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: themeColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                AppSpacer.p8,
                Text(
                  _buildMeta(l10n, localeCode),
                  style: textTheme.labelSmall?.copyWith(
                    color: themeColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildMeta(AppLocalizations l10n, String localeCode) {
    final count = l10n.folderCardNotesCount(folder.notesCount);
    final timeAgo = _formatTimeAgo(folder.updatedAt, l10n, localeCode);

    return '$count • $timeAgo';
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
