import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/l10n/note_transcription_help_topic_l10n.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/app_bottom_sheet.dart';

class NoteTranscriptionExplanationSheet extends StatelessWidget {
  final String title;
  final String description;
  final String note;

  const NoteTranscriptionExplanationSheet({
    required this.title,
    required this.description,
    this.note = '',
    super.key,
  });

  static Future<void> showTopic(
    BuildContext context,
    NoteTranscriptionHelpTopic topic,
  ) {
    final l10n = context.l10n;

    return _show(
      context,
      title: topic.title(l10n),
      description: topic.description(l10n),
      note: topic.note(l10n),
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String title,
    required String description,
    String note = '',
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      useRootNavigator: true,
      child: NoteTranscriptionExplanationSheet(
        title: title,
        description: description,
        note: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;
    final paragraphs = description.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: AppSizes.p12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSizes.p24,
              height: AppSizes.p24,
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
            Expanded(child: Text(title, style: textTheme.headlineSmall)),
          ],
        ),
        AppSpacer.p16,
        for (var i = 0; i < paragraphs.length; i++) ...[
          Text(
            paragraphs[i],
            style: textTheme.bodyMedium?.copyWith(
              color: themeColors.textSecondary,
            ),
          ),
          if (i != paragraphs.length - 1) AppSpacer.p12,
        ],
        AppSpacer.p16,
        if (note.trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(
              color: themeColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(
                color: themeColors.info.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              note,
              style: textTheme.bodySmall?.copyWith(color: themeColors.info),
            ),
          ),
      ],
    );
  }
}
