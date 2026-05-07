import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/asr_transcription_strategy_l10n.dart';
import 'package:voice_notes/core/l10n/note_transcription_help_topic_l10n.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_meta_entity.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_info_chip.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_transcription_explanation_sheet.dart';
import 'package:voice_notes/feature/presentation/widgets/conditional/conditional_wrapper.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class NoteTechnicalInfoAccordion extends StatefulWidget {
  final NoteTranscriptionMetaEntity transcription;

  const NoteTechnicalInfoAccordion({required this.transcription, super.key});

  @override
  State<NoteTechnicalInfoAccordion> createState() =>
      _NoteTechnicalInfoAccordionState();
}

class _NoteTechnicalInfoAccordionState
    extends State<NoteTechnicalInfoAccordion> {
  bool _isExpanded = false;

  List<_TechnicalRowData> _buildRows(AppLocalizations l10n) {
    final transcription = widget.transcription;

    return <_TechnicalRowData>[
      _TechnicalRowData(
        label: l10n.noteInfoTechnicalStrategy,
        value: transcription.strategyUsed.title(l10n),
        topic: NoteTranscriptionHelpTopic.recognitionMode,
      ),
      _TechnicalRowData(
        label: l10n.noteInfoTechnicalSpeechDetection,
        value: _formatBool(transcription.usedVad, l10n),
        topic: NoteTranscriptionHelpTopic.speechDetection,
      ),
      _TechnicalRowData(
        label: l10n.noteInfoTechnicalFallbackMode,
        value: _formatBool(transcription.fellBackFromVad, l10n),
        topic: NoteTranscriptionHelpTopic.fallbackMode,
      ),
      _TechnicalRowData(
        label: l10n.noteInfoTechnicalTextNormalization,
        value: _formatNullableBool(transcription.usedItn, l10n),
        topic: NoteTranscriptionHelpTopic.textNormalization,
      ),
      _TechnicalRowData(
        label: l10n.noteInfoTechnicalAutoPunctuation,
        value: _formatNullableBool(transcription.usedPunctuation, l10n),
        topic: NoteTranscriptionHelpTopic.autoPunctuation,
      ),
    ];
  }

  void _handleExpansionChanged(bool isExpanded) {
    setState(() => _isExpanded = isExpanded);
  }

  VoidCallback? _buildTopicHandler(
    BuildContext context,
    NoteTranscriptionHelpTopic? topic,
  ) {
    if (topic == null) return null;

    return () => NoteTranscriptionExplanationSheet.showTopic(context, topic);
  }

  String _formatBool(bool value, AppLocalizations l10n) {
    return value ? l10n.noteInfoValueYes : l10n.noteInfoValueNo;
  }

  String _formatNullableBool(bool? value, AppLocalizations l10n) {
    if (value == null) return l10n.noteInfoValueNoData;

    return _formatBool(value, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final themeColors = context.themeColors;
    final rows = _buildRows(l10n);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      side: BorderSide(color: themeColors.borderPrimary),
    );

    return Theme(
      data: theme.copyWith(
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: ExpansionTile(
        onExpansionChanged: _handleExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(
          vertical: AppSizes.p4,
          horizontal: AppSizes.cardPadding,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSizes.cardPadding,
          0,
          AppSizes.cardPadding,
          AppSizes.cardPadding,
        ),
        shape: shape,
        collapsedShape: shape,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        backgroundColor: themeColors.bgSecondary,
        collapsedBackgroundColor: themeColors.bgSecondary,
        iconColor: themeColors.textSecondary,
        collapsedIconColor: themeColors.textSecondary,
        textColor: textTheme.titleMedium?.color,
        collapsedTextColor: textTheme.titleMedium?.color,
        title: Text(
          l10n.noteInfoTechnicalCardTitle,
          style: textTheme.titleMedium,
        ),
        subtitle: _isExpanded ? null : _NoteTechnicalSubtitle(rows: rows),
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i == 0) const Divider(height: 1),
            _TechnicalInfoRow(
              label: rows[i].label,
              value: rows[i].value,
              onTap: _buildTopicHandler(context, rows[i].topic),
            ),
            if (i != rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _NoteTechnicalSubtitle extends StatelessWidget {
  final List<_TechnicalRowData> rows;

  const _NoteTechnicalSubtitle({required this.rows, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.p10,
        children: [
          Text(
            l10n.noteInfoTechnicalCardSubtitle,
            style: textTheme.bodySmall?.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [
              NoteInfoChip(
                text: l10n.noteInfoTechnicalParametersCount(rows.length),
              ),
              NoteInfoChip(text: l10n.noteInfoTechnicalReadOnly),
            ],
          ),
        ],
      ),
    );
  }
}

class _TechnicalRowData {
  final String label;
  final String value;
  final NoteTranscriptionHelpTopic? topic;

  const _TechnicalRowData({
    required this.label,
    required this.value,
    this.topic,
  });
}

class _TechnicalInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _TechnicalInfoRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return ConditionalWrapper(
      condition: onTap != null,
      onAddWrapper: (child) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
        child: Row(
          spacing: AppSizes.p12,
          children: [
            Expanded(
              child: Row(
                spacing: AppSizes.p6,
                children: [
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: themeColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Container(
                      width: AppSizes.iconSmall + AppSizes.p4,
                      height: AppSizes.iconSmall + AppSizes.p4,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: themeColors.info.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: AppSizes.iconSmall,
                        color: themeColors.info,
                      ),
                    ),
                ],
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
