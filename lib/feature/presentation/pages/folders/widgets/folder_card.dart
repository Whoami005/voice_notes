import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/folder.dart';

class FolderCard extends StatelessWidget {
  final Folder folder;
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
            _IconContainer(color: folder.color, icon: folder.icon),
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
  final Folder folder;

  const _TextContent({required this.folder});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

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
          _buildSubtitle(),
          style: textTheme.labelMedium?.copyWith(
            color: themeColors.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _buildSubtitle() {
    final count = folder.notesCount;
    final noteWord = _pluralize(count, 'заметка', 'заметки', 'заметок');
    final timeAgo = _formatTimeAgo(folder.lastUpdated);
    return '$count $noteWord • $timeAgo';
  }

  String _pluralize(int count, String one, String few, String many) {
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (mod100 >= 11 && mod100 <= 19) return many;
    if (mod10 == 1) return one;
    if (mod10 >= 2 && mod10 <= 4) return few;
    return many;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      final day = dateTime.day;
      final month = _monthName(dateTime.month);
      return '$day $month';
    }
  }

  String _monthName(int month) {
    const months = [
      'янв.',
      'февр.',
      'марта',
      'апр.',
      'мая',
      'июня',
      'июля',
      'авг.',
      'сент.',
      'окт.',
      'нояб.',
      'дек.',
    ];
    return months[month - 1];
  }
}
