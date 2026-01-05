import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/state.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_detail_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_detail_body.dart';
import 'package:voice_notes/feature/presentation/widgets/base_pop_scope.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/unsaved_changes_dialog.dart';

class NoteDetailScreen extends StatelessWidget implements AppRouteWrapper {
  final String folderId;
  final String noteId;

  const NoteDetailScreen({
    required this.folderId,
    required this.noteId,
    super.key,
  });

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => NoteDetailCubit(
        noteRepository: getIt<NoteRepository>(),
        noteId: noteId,
      ),
      child: this,
    );
  }

  Future<void> _showUnsavedChangesDialog(BuildContext context) async {
    final result = await UnsavedChangesDialog.show(context);

    if (!context.mounted) return;

    if (result ?? false) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BaseStateScaffold<NoteDetailCubit, NoteDetailData>(
      title: 'Заметка',
      onSuccess: (context, _) {
        return BasePopScope(
          canPop: (context) =>
              !context.select((NoteDetailCubit c) => c.requireData.hasChanges),
          onPopInvokedWithResult: () => _showUnsavedChangesDialog(context),
          child: const Scaffold(
            appBar: NoteDetailAppBar(),
            body: NoteDetailBody(),
          ),
        );
      },
    );
  }
}
