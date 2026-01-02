import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/base_state.dart';
import 'package:voice_notes/core/state/base_state_builder.dart';
import 'package:voice_notes/feature/domain/enums/recording_state.dart'
    show SearchFilter;
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/notes/logic/folder_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/notes/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/folder_detail_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/folder_detail_recording_bar.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/note_details_widget.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/search_bar_with_filters.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

class FolderDetailScreen extends StatefulWidget implements AppRouteWrapper {
  final String folderId;

  const FolderDetailScreen({required this.folderId, super.key});

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
    final themeColors = context.themeColors;

    return BaseStateBuilder<FolderDetailCubit, FolderDetailData>(
      buildWhen: (c, p) =>
          c.runtimeType != p.runtimeType ||
          c.dataOrNull?.folder != p.dataOrNull?.folder,
      onSuccess: (context, data) {
        return Scaffold(
          extendBody: true,
          backgroundColor: themeColors.bgPrimary,
          appBar: FolderDetailAppBar(
            folder: data.folder,
            isSearchVisible: _isSearchVisible,
            onToggleSearch: _toggleSearch,
            onEditFolder: _onEditFolder,
            onDeleteFolder: _onDeleteFolder,
          ),
          bottomNavigationBar: FolderDetailRecordingBar(
            onUploadFile: _onUploadFile,
          ),
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
                const NoteDetailsWidget(),
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
      await context.read<FolderDetailCubit>().deleteFolder();
      if (mounted) context.pop();
    }
  }

  void _onUploadFile() {
    // TODO: Open file picker
  }
}
