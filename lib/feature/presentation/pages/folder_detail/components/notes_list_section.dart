import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/state/state.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/date_separator.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/note_bubble.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/screens/note_detail_screen.dart';
import 'package:voice_notes/feature/presentation/widgets/lists/bloc_grouped_sliver_list.dart';

class NotesListSection extends StatelessWidget {
  const NotesListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocGroupedSliverList<
      FolderDetailCubit,
      BaseState<FolderDetailData>,
      NoteEntity
    >(
      selector: (state) => state.requireData.groupedNotes,
      buildWhen: (prev, curr) =>
          prev.requireData.groupedNotes != curr.requireData.groupedNotes,
      padding: const EdgeInsets.only(
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        top: AppSizes.p8,
        bottom: 130,
      ),
      headerBuilder: (context, label) => DateSeparator(date: label),
      itemBuilder: (context, note, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.p12),
        child: NoteBubble(
          note: note,
          onTap: () {
            final folderId = context.read<FolderDetailCubit>().folderId;
            NoteDetailScreen.go(context, folderId: folderId, noteId: note.uuid);
          },
          onCopy: () => Clipboard.setData(ClipboardData(text: note.text)),
          onShare: () {},
        ),
      ),
    );
  }
}
