import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_info_block_title.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_info_card.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_info_chip.dart';

class NoteAiLabelsBlock extends StatelessWidget {
  final List<String> labels;

  const NoteAiLabelsBlock({required this.labels, super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.p8,
      children: [
        NoteInfoBlockTitle(title: context.l10n.noteInfoAiLabelsTitle),
        NoteInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSizes.p8,
            children: [
              Wrap(
                spacing: AppSizes.p8,
                runSpacing: AppSizes.p8,
                children: [
                  for (final label in labels) NoteInfoChip(text: label),
                ],
              ),
              Text(
                context.l10n.noteInfoAiLabelsHint,
                style: textTheme.bodySmall?.copyWith(
                  color: themeColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
