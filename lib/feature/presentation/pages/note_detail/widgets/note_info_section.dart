import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_ai_labels_block.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_primary_info_card.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_technical_info_block.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class NoteInfoSection extends StatelessWidget {
  final NoteEntity note;

  const NoteInfoSection({required this.note, super.key});

  List<String> _buildAiLabels(AppLocalizations l10n) {
    final transcription = note.origin.transcription;

    return [
      if (transcription?.emotionLabel?.trim().isNotEmpty ?? false)
        '${l10n.noteInfoEmotion}: ${transcription!.emotionLabel!.trim()}',
      if (transcription?.eventLabel?.trim().isNotEmpty ?? false)
        '${l10n.noteInfoEvent}: ${transcription!.eventLabel!.trim()}',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final aiLabels = _buildAiLabels(l10n);
    final transcription = note.origin.transcription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.p12,
      children: [
        NotePrimaryInfoCard(note: note),
        if (aiLabels.isNotEmpty) NoteAiLabelsBlock(labels: aiLabels),
        if (transcription != null)
          NoteTechnicalInfoBlock(transcription: transcription),
      ],
    );
  }
}
