import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/presentation/widgets/chips/tag_chip.dart';

class NoteBubble extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const NoteBubble({
    required this.note,
    this.onTap,
    this.onCopy,
    this.onShare,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final screenWidth = context.screenSize.width;

    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p14,
          ),
          decoration: BoxDecoration(
            color: themeColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppSizes.bubbleRadius),
            border: Border.all(color: themeColors.borderPrimary),
          ),
          child: Column(
            spacing: AppSizes.p8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.text,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              if (note.tags.isNotEmpty)
                Wrap(
                  spacing: AppSizes.p6,
                  runSpacing: AppSizes.p6,
                  children: List.generate(
                    note.tags.length,
                    (index) => TagChip(label: note.tags[index].name),
                  ),
                ),
              _MetaInfo(note: note),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  final NoteEntity note;

  const _MetaInfo({required this.note});

  @override
  Widget build(BuildContext context) {
    final metaStyle = context.textTheme.labelSmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_formatTime(note.createdAt), style: metaStyle),
        const _Dot(),
        Text(_formatDuration(note.duration), style: metaStyle),
        const _Dot(),
        Text(note.language, style: metaStyle),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    final color = context.themeColors.textTertiary;

    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
