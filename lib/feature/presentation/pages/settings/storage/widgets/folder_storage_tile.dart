import 'package:flutter/material.dart';
import 'package:voice_notes/common/utils/format_bytes.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/folder_storage_stats.dart';
import 'package:voice_notes/feature/presentation/widgets/folder_icon_badge.dart';

/// Строка списка папок на главном экране Storage.
///
/// Отображает иконку и имя папки (или «Без папки»), общий размер аудио
/// и счётчик записей. По тапу — переход на FolderStorageScreen.
class FolderStorageTile extends StatelessWidget {
  final FolderStorageStats stats;
  final VoidCallback onTap;

  const FolderStorageTile({
    required this.stats,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    final folder = stats.folder;
    final folderColor = folder?.color ?? themeColors.textTertiary;
    final folderName = folder?.name ?? l10n.storageWithoutFolder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p12,
        ),
        child: Row(
          children: [
            FolderIconBadge(
              icon: folder?.icon,
              color: folderColor,
              size: AppSizes.avatarSmall,
              iconSize: AppSizes.iconMedium,
              borderRadius: AppSizes.radiusMedium,
              fallbackIcon: Icons.folder_off_outlined,
            ),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      color: themeColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    l10n.storageRecordingsCount(stats.count),
                    style: textTheme.bodySmall?.copyWith(
                      color: themeColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.p8),
            Text(
              BytesFormatter.format(stats.bytes),
              style: textTheme.bodyMedium?.copyWith(
                color: themeColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSizes.p4),
            Icon(
              Icons.chevron_right_rounded,
              color: themeColors.textTertiary,
              size: AppSizes.iconMedium,
            ),
          ],
        ),
      ),
    );
  }
}
