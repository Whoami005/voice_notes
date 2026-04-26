import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/note_ingestion/note_ingestion_service.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/state/async/async_state_widgets.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/components/notes_list_section.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_playback_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/folder_detail_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/folder_detail_recording_bar.dart';
import 'package:voice_notes/feature/presentation/widgets/asr_status_banner.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

class FolderDetailScreen extends StatefulWidget implements AppRouteWrapper {
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

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final bool _isSearchVisible = false;

  // String _searchQuery = '';
  // SearchFilter _activeFilter = SearchFilter.all;

  @override
  Widget build(BuildContext context) {
    return AsyncStateScaffold<FolderDetailCubit, FolderDetailData>(
      title: context.l10n.folderDetailTitle,
      onSuccess: (context, _) {
        return Scaffold(
          extendBody: true,
          appBar: FolderDetailAppBar(
            isSearchVisible: _isSearchVisible,
            onToggleSearch: _toggleSearch,
            onEditFolder: _onEditFolder,
            onDeleteFolder: _onDeleteFolder,
          ),
          bottomNavigationBar: const FolderDetailRecordingBar(),
          body: const RefreshableWrapper<FolderDetailCubit>(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                AsrStatusBanner.sliver(),
                // if (hasDescription)
                //   SliverToBoxAdapter(
                //     child: Padding(
                //       padding: const EdgeInsets.fromLTRB(
                //         AppSizes.screenPadding,
                //         AppSizes.p12,
                //         AppSizes.screenPadding,
                //         AppSizes.p4,
                //       ),
                //       child: FolderAboutCard(folder: folder),
                //     ),
                //   ),
                NotesListSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleSearch() {
    // setState(() {
    //   _isSearchVisible = !_isSearchVisible;
    //   if (!_isSearchVisible) {
    //     _searchQuery = '';
    //     _activeFilter = SearchFilter.all;
    //   }
    // });
  }

  void _onEditFolder() {
    // TODO(W): Open edit folder sheet
  }

  Future<void> _onDeleteFolder() async {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.deleteFolderTitle,
      message: l10n.deleteFolderMessageGeneric,
      confirmText: l10n.dialogDelete,
      confirmColor: themeColors.error,
    );

    if ((confirmed ?? false) && mounted) {
      final deleted = await context.read<FolderDetailCubit>().deleteFolder();
      if (deleted && mounted) context.pop();
    }
  }
}
