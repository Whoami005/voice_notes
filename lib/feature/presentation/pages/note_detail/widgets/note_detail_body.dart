import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/state/base_state/base_state.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_detail_cubit.dart';
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
    ).showSnackBar(const SnackBar(content: Text('Текст скопирован')));
  }

  Future<void> _onDelete(BuildContext context) async {
    final cubit = context.read<NoteDetailCubit>();
    final themeColors = context.themeColors;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Удалить заметку?',
      message: 'Это действие нельзя отменить.',
      confirmText: 'Удалить',
      confirmColor: themeColors.error,
    );

    if (confirmed ?? false) {
      final deleted = await cubit.deleteNote();
      if (deleted && context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoteDetailCubit, BaseState<NoteDetailData>>(
      builder: (context, state) {
        final data = state.requireData;

        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            const SectionHeader(title: 'Текст'),
            AppSpacer.p12,
            NoteTextSection(
              key: ValueKey(data.originalNote.uuid),
              text: data.currentNote.text,
              isEditing: data.isEditing,
              onChanged: (text) =>
                  context.read<NoteDetailCubit>().updateText(text),
            ),
            AppSpacer.p24,
            const SectionHeader(title: 'Теги'),
            AppSpacer.p12,
            NoteTagsSection(
              tags: data.currentNote.tags,
              isEditing: data.isEditing,
              onAddTag: (tag) => context.read<NoteDetailCubit>().addTag(tag),
              onRemoveTag: (tag) =>
                  context.read<NoteDetailCubit>().removeTag(tag),
            ),
            AppSpacer.p24,
            const SectionHeader(title: 'Информация'),
            AppSpacer.p12,
            NoteInfoSection(note: data.currentNote),
            AppSpacer.p24,
            const SectionHeader(title: 'Действия'),
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
