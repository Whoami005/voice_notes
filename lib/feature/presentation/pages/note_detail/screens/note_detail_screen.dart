import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/async/async_state_widgets.dart';
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

  /// Навигация на экран деталей заметки
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
    return AsyncStateScaffold<NoteDetailCubit, NoteDetailData>(
      title: context.l10n.noteDetailTitle,
      onSuccess: (context, data) {
        return BasePopScope(
          canPop: (context) => !data.hasChanges,
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
