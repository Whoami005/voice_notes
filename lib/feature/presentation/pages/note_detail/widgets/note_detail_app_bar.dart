import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/state/base_state/base_state.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/base_preferred_app_bar.dart';

class NoteDetailAppBar extends BasePreferredAppBar {
  const NoteDetailAppBar({super.key});

  @override
  State<NoteDetailAppBar> createState() => _NoteDetailAppBarState();
}

class _NoteDetailAppBarState extends State<NoteDetailAppBar> {
  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return BlocBuilder<NoteDetailCubit, BaseState<NoteDetailData>>(
      buildWhen: (p, c) =>
          p.requireData.isEditing != c.requireData.isEditing ||
          p.requireData.hasChanges != c.requireData.hasChanges,
      builder: (context, state) {
        final data = state.requireData;

        return AppBar(
          title: const Text('Заметка'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
          actions: [
            if (data.isEditing) ...[
              // Кнопка отмены
              IconButton(
                icon: Icon(Icons.close, color: themeColors.textSecondary),
                onPressed: () =>
                    context.read<NoteDetailCubit>().cancelEditing(),
              ),
              // Кнопка сохранения
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: data.hasChanges
                      ? themeColors.accentPrimary
                      : themeColors.textTertiary,
                ),
                onPressed: data.hasChanges
                    ? () => context.read<NoteDetailCubit>().saveNote()
                    : null,
              ),
            ] else
              // Кнопка редактирования
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: themeColors.textSecondary,
                ),
                onPressed: () => context.read<NoteDetailCubit>().startEditing(),
              ),
          ],
        );
      },
    );
  }
}
