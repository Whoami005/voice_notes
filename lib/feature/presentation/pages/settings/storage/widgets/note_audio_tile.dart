import 'package:flutter/material.dart';
import 'package:voice_notes/common/utils/format_bytes.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_stats.dart';

/// Строка списка на FolderStorageScreen: одна заметка с аудио.
///
/// Показывает превью текста заметки, размер и длительность оригинала.
/// Поддерживает swipe-to-delete для точечного удаления аудио (заметка
/// при этом остаётся).
class NoteAudioTile extends StatelessWidget {
  final NoteAudioStats stats;
  final Future<bool> Function() onDismissRequest;

  const NoteAudioTile({
    required this.stats,
    required this.onDismissRequest,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    final note = stats.note;
    final preview = note.text.trim().isEmpty
        ? '—'
        : note.text.replaceAll(RegExp(r'\s+'), ' ');

    return Dismissible(
      key: ValueKey('note_audio_${note.uuid}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
        decoration: BoxDecoration(
          color: themeColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: themeColors.error),
            AppSpacer.p8,
            Text(
              l10n.storageDeleteNoteAudio,
              style: textTheme.bodyMedium?.copyWith(color: themeColors.error),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) => onDismissRequest(),
      child: Container(
        decoration: BoxDecoration(
          color: themeColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: themeColors.borderPrimary),
        ),
        padding: const EdgeInsets.all(AppSizes.p12),
        child: Row(
          children: [
            Icon(
              Icons.audiotrack_rounded,
              color: themeColors.accentPrimary,
              size: AppSizes.iconLarge,
            ),
            AppSpacer.p12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: themeColors.textPrimary,
                    ),
                  ),
                  AppSpacer.p2,
                  Text(
                    '${_formatDuration(stats.duration)} · '
                    '${BytesFormatter.format(stats.bytes)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: themeColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
