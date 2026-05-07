import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/state/async/async_state_widgets.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_playback_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/audio_player_bar.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_actions_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_detail_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_info_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_tags_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_text_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/pending_placeholder.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/section_header.dart';
import 'package:voice_notes/feature/presentation/widgets/base_pop_scope.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/unsaved_changes_dialog.dart';

class NoteDetailScreen extends StatelessWidget implements AppRouteWrapper {
  final String folderId;
  final String noteId;

  const NoteDetailScreen({
    required this.folderId,
    required this.noteId,
    super.key,
  });

  static void go(
    BuildContext context, {
    required String folderId,
    required String noteId,
  }) {
    context.go(
      AppRoutes.folders.noteDetail(folderId: folderId, noteId: noteId),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => NoteDetailCubit(
            noteRepository: getIt<NoteRepository>(),
            noteId: noteId,
          ),
        ),
        BlocProvider(
          create: (_) => NotePlaybackCubit(
            controller: getIt<AudioPlaybackController>(),
            folderId: folderId,
            noteId: noteId,
          ),
        ),
      ],
      child: this,
    );
  }

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

  Future<void> _showUnsavedChangesDialog(BuildContext context) async {
    final result = await UnsavedChangesDialog.show(context);

    if (!context.mounted) return;

    if (result ?? false) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStateScaffold<NoteDetailCubit, NoteDetailData>(
      buildAlways: true,
      title: context.l10n.noteDetailTitle,
      onSuccess: (context, data) {
        final cubit = context.read<NoteDetailCubit>();
        final note = data.currentNote;

        if (!note.isCompleted) return PendingPlaceholder(note: note);

        return BasePopScope(
          canPop: (context) => !data.hasChanges,
          onPopInvokedWithResult: () => _showUnsavedChangesDialog(context),
          child: Scaffold(
            appBar: const NoteDetailAppBar(),
            body: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                if (note.origin.audio != null) ...[
                  AudioPlayerBar(note: note),
                  AppSpacer.p24,
                ],
                SectionHeader(title: context.l10n.noteDetailSectionText),
                AppSpacer.p12,
                NoteTextSection(
                  key: ValueKey(data.originalNote.uuid),
                  text: note.text,
                  isEditing: data.isEditing,
                  onChanged: cubit.updateText,
                ),
                AppSpacer.p24,
                SectionHeader(title: context.l10n.noteDetailSectionTags),
                AppSpacer.p12,
                NoteTagsSection(
                  tags: note.tags,
                  isEditing: data.isEditing,
                  onAddTag: cubit.addTag,
                  onRemoveTag: cubit.removeTag,
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
            ),
          ),
        );
      },
    );
  }
}
