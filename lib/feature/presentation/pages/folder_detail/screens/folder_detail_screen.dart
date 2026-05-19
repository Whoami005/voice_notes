import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/adaptive/adaptive.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_pane_route_presentation.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/app_router/routes/folders_route_presentation.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/note_ingestion/note_ingestion_service.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/state/async/async_state_widgets.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/components/notes_list_section.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/folder_detail_adaptive.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_playback_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/folder_detail_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/folder_detail_recording_bar.dart';
import 'package:voice_notes/feature/presentation/widgets/asr_status_banner.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

class FolderDetailScreen extends StatelessWidget implements AppRouteWrapper {
  final String folderId;

  const FolderDetailScreen({required this.folderId, super.key});

  static void go(BuildContext context, {required String folderId}) {
    context.router.go(AppRoutes.folders.detail(folderId));
  }

  static void push(BuildContext context, {required String folderId}) {
    context.router.push(AppRoutes.folders.detail(folderId));
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FolderDetailCubit(
            noteRepository: getIt<NoteRepository>(),
            folderRepository: getIt<FolderRepository>(),
            folderId: folderId,
          ),
        ),
        BlocProvider(
          create: (_) => RecordingCubit(
            folderId: folderId,
            recordingService: getIt<AudioRecordingService>(),
            queueController: getIt<TranscriptionQueueController>(),
            noteRepository: getIt<NoteRepository>(),
            playbackController: getIt<AudioPlaybackController>(),
            ingestionService: getIt<NoteIngestionService>(),
          ),
        ),
        BlocProvider(
          create: (_) => FolderPlaybackCubit(
            folderId: folderId,
            controller: getIt<AudioPlaybackController>(),
            noteRepository: getIt<NoteRepository>(),
          ),
        ),
      ],
      child: this,
    );
  }

  Future<void> _onDeleteFolder(BuildContext context) async {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.deleteFolderTitle,
      message: l10n.deleteFolderMessageGeneric,
      confirmText: l10n.dialogDelete,
      confirmColor: themeColors.error,
    );

    if ((confirmed ?? false) && context.mounted) {
      final deleted = await context.read<FolderDetailCubit>().deleteFolder();
      if (deleted && context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final windowClass = context.windowClass;
    final presentation = FoldersRoutePresentation.fromContext(context);
    final backgroundColor = presentation.backgroundColor(context);

    return AsyncStateScaffold<FolderDetailCubit, FolderDetailData>(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: presentation.automaticallyImplyLeading,
        backgroundColor: backgroundColor,
        title: Text(context.l10n.folderDetailTitle),
      ),
      onSuccess: (context, _) {
        final detailBody =
            FolderDetailAdaptive.useCenteredContent(windowClass)
            ? const AdaptiveContentWidth(
                maxWidth: FolderDetailAdaptive.contentMaxWidth,
                alignment: Alignment.topCenter,
                child: _FolderDetailScrollView(),
              )
            : const _FolderDetailScrollView();

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: FolderDetailAppBar(
            onDeleteFolder: () => _onDeleteFolder(context),
            showBackButton: presentation.automaticallyImplyLeading,
          ),
          bottomNavigationBar: const FolderDetailRecordingBar(),
          body: RefreshableWrapper<FolderDetailCubit>(child: detailBody),
        );
      },
    );
  }
}

class _FolderDetailScrollView extends StatelessWidget {
  const _FolderDetailScrollView();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        AsrStatusBanner.sliver(),
        NotesListSection(),
      ],
    );
  }
}
