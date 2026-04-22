import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/audio_player_bar.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_actions_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_info_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_tags_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_text_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/section_header.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';

class NoteDetailBody extends StatelessWidget {
  const NoteDetailBody({super.key});

  Future<void> _onCopy(BuildContext context, NoteDetailData data) async {
    await Clipboard.setData(ClipboardData(text: data.currentNote.text));
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.noteDetailTextCopied)));
  }

  Future<void> _onDelete(BuildContext context) async {
    final cubit = context.read<NoteDetailCubit>();
    final themeColors = context.themeColors;

    final l10n = context.l10n;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.deleteNoteTitle,
      message: l10n.deleteNoteMessage,
      confirmText: l10n.dialogDelete,
      confirmColor: themeColors.error,
    );

    if (confirmed ?? false) {
      final deleted = await cubit.deleteNote();
      if (deleted && context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteDetailCubit, AsyncState<NoteDetailData>>(
      builder: (context, state) {
        final data = state.requireData;
        final note = data.currentNote;
        final audio = note.audio;

        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            if (audio != null) ...[AudioPlayerBar(note: note), AppSpacer.p24],
            SectionHeader(title: context.l10n.noteDetailSectionText),
            AppSpacer.p12,
            NoteTextSection(
              key: ValueKey(data.originalNote.uuid),
              text: note.text,
              isEditing: data.isEditing,
              onChanged: (text) =>
                  context.read<NoteDetailCubit>().updateText(text),
            ),
            AppSpacer.p24,
            SectionHeader(title: context.l10n.noteDetailSectionTags),
            AppSpacer.p12,
            NoteTagsSection(
              tags: note.tags,
              isEditing: data.isEditing,
              onAddTag: (tag) => context.read<NoteDetailCubit>().addTag(tag),
              onRemoveTag: (tag) =>
                  context.read<NoteDetailCubit>().removeTag(tag),
            ),
            AppSpacer.p24,
            SectionHeader(title: context.l10n.noteDetailSectionInfo),
            AppSpacer.p12,
            NoteInfoSection(note: note),
            AppSpacer.p24,
            SectionHeader(title: context.l10n.noteDetailSectionActions),
            AppSpacer.p12,
            NoteActionsSection(
              onCopy: () => _onCopy(context, data),
              onDelete: () => _onDelete(context),
            ),
            AppSpacer.p32,
          ],
        );
      },
    );
  }
}
