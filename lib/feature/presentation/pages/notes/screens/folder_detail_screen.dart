import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/enums/recording_state.dart'
    show SearchFilter;
import 'package:voice_notes/feature/presentation/pages/notes/logic/recording_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/date_separator.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/note_bubble.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/recording_input.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/search_bar_with_filters.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/menus/dropdown_menu.dart';

class FolderDetailScreen extends StatefulWidget implements AppRouteWrapper {
  final String folderId;

  const FolderDetailScreen({required this.folderId, super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => RecordingCubit(
        recordingService: getIt<AudioRecordingService>(),
        asrService: getIt<AsrService>(),
        folderId: folderId,
        onNoteCreated: (text) {
          // TODO: Обновить список заметок когда будет NoteRepository
        },
      ),
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

  // Mock folder data
  late final FolderEntity _folder;

  // Mock notes data grouped by date
  final List<_DateGroup> _noteGroups = [];

  @override
  void initState() {
    super.initState();
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Mock folder based on ID
    _folder = FolderEntity(
      uid: widget.folderId,
      name: 'Работа',
      description: 'Рабочие заметки и митинги',
      color: AppColors.folderColors[2],
      icon: MaterialIconRefEntity(Icons.work.codePoint),
      notesCount: 15,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    );

    _noteGroups.addAll([
      _DateGroup(
        label: 'Сегодня',
        notes: [
          NoteEntity(
            uuid: '1',
            text:
                'Обсудили план на следующий спринт. Нужно добавить новый '
                'функционал для авторизации и интеграцию с внешним API.',
            createdAt: now.subtract(const Duration(hours: 1)),
            updatedAt: now.subtract(const Duration(hours: 1)),
            duration: const Duration(seconds: 45),
            modelName: 'Whisper Small',
            language: 'Русский',
            wordCount: 18,
            tags: [
              TagEntity(uid: '1', name: 'работа', createdAt: now),
              TagEntity(uid: '2', name: 'спринт', createdAt: now),
            ],
          ),
          NoteEntity(
            uuid: '2',
            text:
                'Записка о встрече с клиентом. Нужно подготовить '
                'презентацию до пятницы.',
            createdAt: now.subtract(const Duration(hours: 3)),
            updatedAt: now.subtract(const Duration(hours: 3)),
            duration: const Duration(seconds: 32),
            modelName: 'Whisper Small',
            language: 'Русский',
            wordCount: 11,
            tags: [
              TagEntity(uid: '3', name: 'клиент', createdAt: now),
              TagEntity(uid: '4', name: 'презентация', createdAt: now),
            ],
          ),
        ],
      ),
      _DateGroup(
        label: 'Вчера',
        notes: [
          NoteEntity(
            uuid: '3',
            text:
                'Идея для нового проекта: приложение для трекинга привычек '
                'с геймификацией.',
            createdAt: yesterday.subtract(const Duration(hours: 5)),
            updatedAt: yesterday.subtract(const Duration(hours: 5)),
            duration: const Duration(seconds: 28),
            modelName: 'Whisper Small',
            language: 'Русский',
            wordCount: 10,
            tags: [TagEntity(uid: '5', name: 'идея', createdAt: yesterday)],
          ),
        ],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: themeColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: themeColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _folder.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.p8),
              ),
              child: Icon(_folder.iconData, color: _folder.color, size: 18),
            ),
            AppSpacer.p10,
            Flexible(
              child: Text(
                _folder.name,
                style: textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: themeColors.textSecondary,
            ),
            onPressed: _toggleSearch,
          ),
          AppDropdownMenu(
            offset: const Offset(-140, 0),
            items: [
              AppMenuItem(
                icon: Icons.edit_outlined,
                label: 'Редактировать',
                onTap: _onEditFolder,
              ),
              AppMenuItem(
                icon: Icons.delete_outline,
                label: 'Удалить папку',
                color: themeColors.error,
                onTap: _onDeleteFolder,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: BlocConsumer<RecordingCubit, RecordingState>(
        listener: _handleRecordingStateChange,
        builder: (context, state) {
          final cubit = context.read<RecordingCubit>();

          return Padding(
            padding: EdgeInsets.only(
              left: AppSizes.screenPadding,
              right: AppSizes.screenPadding,
              bottom: context.padding.bottom + AppSizes.p16,
            ),
            child: RecordingInput(
              state: state.uiState,
              recordingDuration: state.durationOrNull ?? Duration.zero,
              transcribingText: state is RecordingTranscribingState
                  ? state.partialText
                  : null,
              onStartRecording: cubit.startRecording,
              onStopRecording: cubit.stopRecording,
              onCancelRecording: cubit.cancelRecording,
              onUploadFile: _onUploadFile,
            ),
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: AppSizes.screenPadding,
          right: AppSizes.screenPadding,
          top: AppSizes.p8,
          bottom: 120,
        ),
        children: [
          if (_isSearchVisible) ...[
            SearchBarWithFilters(
              query: _searchQuery,
              onQueryChanged: (q) => setState(() => _searchQuery = q),
              activeFilter: _activeFilter,
              onFilterChanged: (f) => setState(() => _activeFilter = f),
              placeholder: 'Поиск в папке...',
            ),
            AppSpacer.p16,
          ],
          ..._buildNotesList(),
        ],
      ),
    );
  }

  void _handleRecordingStateChange(BuildContext context, RecordingState state) {
    if (state is RecordingSuccessState) {
      _showSuccessToast(context, state);
    } else if (state is RecordingErrorState) {
      _showErrorToast(context, state);
    }
  }

  void _showSuccessToast(BuildContext context, RecordingSuccessState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Заметка создана: ${state.text}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorToast(BuildContext context, RecordingErrorState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.themeColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Widget> _buildNotesList() {
    final widgets = <Widget>[];

    for (final group in _noteGroups) {
      widgets.add(DateSeparator(date: group.label));

      for (final note in group.notes) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.p12),
            child: NoteBubble(
              note: note,
              onTap: () => _onNoteTap(note),
              onCopy: () => _onCopyNote(note),
              onShare: () => _onShareNote(note),
            ),
          ),
        );
      }
    }

    return widgets;
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
      context.pop();
    }
  }

  void _onNoteTap(NoteEntity note) {
    context.go('/folders/${widget.folderId}/note/${note.uuid}');
  }

  void _onCopyNote(NoteEntity note) {
    // TODO: Copy to clipboard
  }

  void _onShareNote(NoteEntity note) {
    // TODO: Share note
  }

  void _onUploadFile() {
    // TODO: Open file picker
  }
}

class _DateGroup {
  final String label;
  final List<NoteEntity> notes;

  const _DateGroup({required this.label, required this.notes});
}
