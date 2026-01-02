import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/state/base_state.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/presentation/pages/notes/logic/folder_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/date_separator.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/note_bubble.dart';
import 'package:voice_notes/feature/presentation/widgets/lists/bloc_grouped_sliver_list.dart';

class NoteDetailsWidget extends StatelessWidget {
  const NoteDetailsWidget({super.key});

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
            context.go('/folders/$folderId/note/${note.uuid}');
          },
          onCopy: () async {
            await Clipboard.setData(ClipboardData(text: note.text));
          },
          onShare: () {},
        ),
      ),
    );
  }
}
