import 'package:flutter/material.dart';
import 'package:voice_notes/common/utils/date_time_formatter.dart';
import 'package:voice_notes/common/utils/duration_formatter.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/localized_models.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_info_card.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_separated_column.dart';

class NotePrimaryInfoCard extends StatelessWidget {
  final NoteEntity note;

  const NotePrimaryInfoCard({required this.note, super.key});

  List<_PrimaryInfoRowData> _buildRows(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final origin = note.origin;

    final transcription = origin.transcription;
    final sourceDuration = origin.sourceDuration;
    final transcriptionSegments = origin.transcriptionSegments;
    final detectedLanguageCode = origin.detectedLanguageCode?.trim() ?? '';
    final transcriptionModelId = origin.transcriptionModelId;
    final modelName = transcriptionModelId == null
        ? null
        : LocalizedModels.name(transcriptionModelId);

    return <_PrimaryInfoRowData>[
      if (sourceDuration != null)
        _PrimaryInfoRowData(
          icon: Icons.timer_outlined,
          label: l10n.noteInfoDuration,
          value: DurationFormatter.compact(sourceDuration),
        ),
      _PrimaryInfoRowData(
        icon: Icons.edit_note_outlined,
        label: l10n.noteInfoSource,
        value: note.origin.isManual
            ? l10n.noteSourceManual
            : l10n.noteSourceAudio,
      ),
      if (modelName != null)
        _PrimaryInfoRowData(
          icon: Icons.memory,
          label: l10n.noteInfoModel,
          value: modelName,
        ),
      if (detectedLanguageCode.isNotEmpty)
        _PrimaryInfoRowData(
          icon: Icons.language,
          label: l10n.noteInfoLanguage,
          value: detectedLanguageCode,
        ),
      if (transcription != null)
        _PrimaryInfoRowData(
          icon: Icons.auto_awesome,
          label: l10n.noteInfoTranscribedAt,
          value: DateTimeFormatter.full(
            transcription.transcribedAt,
            localeCode: localeCode,
          ),
        ),
      if (transcription != null)
        _PrimaryInfoRowData(
          icon: Icons.bolt_outlined,
          label: l10n.noteInfoProcessingTime,
          value: DurationFormatter.compact(transcription.processingTime),
        ),
      if (transcriptionSegments?.isNotEmpty ?? false)
        _PrimaryInfoRowData(
          icon: Icons.segment_outlined,
          label: l10n.noteInfoSegments,
          value: '${transcriptionSegments!.length}',
        ),
      _PrimaryInfoRowData(
        icon: Icons.text_fields,
        label: l10n.noteInfoWords,
        value: '${note.wordCount}',
      ),
      _PrimaryInfoRowData(
        icon: Icons.calendar_today_outlined,
        label: l10n.noteInfoDate,
        value: DateTimeFormatter.full(note.createdAt, localeCode: localeCode),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(context);

    return NoteInfoCard(
      child: NoteSeparatedColumn(
        children: [
          for (final row in rows)
            _PrimaryInfoRow(icon: row.icon, label: row.label, value: row.value),
        ],
      ),
    );
  }
}

class _PrimaryInfoRowData {
  final IconData icon;
  final String label;
  final String value;

  const _PrimaryInfoRowData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _PrimaryInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PrimaryInfoRow({
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
              maxLines: 2,
              style: textTheme.bodyMedium?.copyWith(
                color: themeColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(
                  color: themeColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
