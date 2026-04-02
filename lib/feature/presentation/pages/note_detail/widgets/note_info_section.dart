import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

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
            label: l10n.noteInfoDuration,
            value: _formatDuration(note.duration),
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.language,
            label: l10n.noteInfoLanguage,
            value: note.language,
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.memory,
            label: l10n.noteInfoModel,
            value: note.modelName,
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.text_fields,
            label: l10n.noteInfoWords,
            value: '${note.wordCount}',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.noteInfoDate,
            value: _formatDate(note.createdAt, localeCode),
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

  String _formatDate(DateTime date, String localeCode) {
    final formatter = DateFormat('dd MMMM yyyy, HH:mm', localeCode);
    return formatter.format(date);
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
