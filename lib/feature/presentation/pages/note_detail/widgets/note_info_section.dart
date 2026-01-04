import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';

class NoteInfoSection extends StatelessWidget {
  final NoteEntity note;

  const NoteInfoSection({required this.note, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.timer_outlined,
            label: 'Длительность',
            value: _formatDuration(note.duration),
          ),
          _Divider(),
          _InfoRow(icon: Icons.language, label: 'Язык', value: note.language),
          _Divider(),
          _InfoRow(icon: Icons.memory, label: 'Модель', value: note.modelName),
          _Divider(),
          _InfoRow(
            icon: Icons.text_fields,
            label: 'Слов',
            value: '${note.wordCount}',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Дата',
            value: _formatDate(note.createdAt),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _getMonthName(date.month);
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  String _getMonthName(int month) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return months[month - 1];
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.iconMedium,
            color: themeColors.textTertiary,
          ),
          AppSpacer.p12,
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: themeColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: themeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Divider(color: themeColors.borderPrimary, height: 1);
  }
}
