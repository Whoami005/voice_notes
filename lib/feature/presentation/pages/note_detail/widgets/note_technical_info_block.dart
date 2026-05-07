import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/note_transcription_meta_entity.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_info_block_title.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_technical_info_accordion.dart';

class NoteTechnicalInfoBlock extends StatelessWidget {
  final NoteTranscriptionMetaEntity transcription;

  const NoteTechnicalInfoBlock({required this.transcription, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSizes.p8,
      children: [
        NoteInfoBlockTitle(title: context.l10n.noteInfoTechnicalTitle),
        NoteTechnicalInfoAccordion(transcription: transcription),
      ],
    );
  }
}
