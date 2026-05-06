import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/audio_player_bar.dart';

class PendingPlaceholder extends StatelessWidget {
  final NoteEntity note;

  const PendingPlaceholder({required this.note, super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.noteDetailTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            if (note.audio != null)
              SliverToBoxAdapter(child: AudioPlayerBar(note: note)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  spacing: AppSizes.p16,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: AppSizes.avatarLarge,
                      color: themeColors.textSecondary,
                    ),
                    Text(
                      l10n.noteDetailProcessingTitle,
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
