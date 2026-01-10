import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/async/async_state_widgets.dart';
import 'package:voice_notes/feature/domain/enums/recording_state.dart'
    show SearchFilter;
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/components/notes_list_section.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/folder_detail_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/folder_detail_recording_bar.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/search_bar_with_filters.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

class FolderDetailScreen extends StatefulWidget implements AppRouteWrapper {
  final String folderId;

  const FolderDetailScreen({required this.folderId, super.key});

  /// Навигация на экран деталей папки
  static void go(BuildContext context, {required String folderId}) {
    context.go(AppRoutes.folders.detail(folderId));
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
            recordingService: getIt<AudioRecordingService>(),
            asrService: getIt<AsrService>(),
            noteRepository: getIt<NoteRepository>(),
            folderId: folderId,
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
  bool _isSearchVisible = false;
  String _searchQuery = '';
  SearchFilter _activeFilter = SearchFilter.all;

  @override
  Widget build(BuildContext context) {
    return AsyncStateScaffold<FolderDetailCubit, FolderDetailData>(
      title: 'Папка',
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
          body: RefreshableWrapper<FolderDetailCubit>(
            child: CustomScrollView(
              slivers: [
                if (_isSearchVisible)
                  SliverToBoxAdapter(
                    child: SearchBarWithFilters(
                      padding: const EdgeInsets.only(
                        left: AppSizes.screenPadding,
                        right: AppSizes.screenPadding,
                        bottom: AppSizes.p16,
                      ),
                      query: _searchQuery,
                      onQueryChanged: (q) => setState(() => _searchQuery = q),
                      activeFilter: _activeFilter,
                      onFilterChanged: (f) => setState(() => _activeFilter = f),
                      placeholder: 'Поиск в папке...',
                    ),
                  ),
                const NotesListSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchQuery = '';
        _activeFilter = SearchFilter.all;
      }
    });
  }

  void _onEditFolder() {
    // TODO: Open edit folder sheet
  }

  Future<void> _onDeleteFolder() async {
    final themeColors = context.themeColors;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Удалить папку?',
      message: 'Все заметки в этой папке будут удалены безвозвратно.',
      confirmText: 'Удалить',
      confirmColor: themeColors.error,
    );

    if ((confirmed ?? false) && mounted) {
      final deleted = await context.read<FolderDetailCubit>().deleteFolder();
      if (deleted && mounted) context.pop();
    }
  }
}
