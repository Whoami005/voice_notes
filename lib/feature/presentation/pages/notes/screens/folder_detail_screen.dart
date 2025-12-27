import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/feature/domain/folder.dart';
import 'package:voice_notes/feature/domain/note.dart';
import 'package:voice_notes/feature/domain/recording_state.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/date_separator.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/note_bubble.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/recording_input.dart';
import 'package:voice_notes/feature/presentation/pages/notes/widgets/search_bar_with_filters.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';
import 'package:voice_notes/feature/presentation/widgets/menus/dropdown_menu.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderId;

  const FolderDetailScreen({required this.folderId, super.key});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  bool _isSearchVisible = false;
  String _searchQuery = '';
  SearchFilter _activeFilter = SearchFilter.all;
  RecordingState _recordingState = RecordingState.idle;
  Duration _recordingDuration = Duration.zero;

  // Mock folder data
  late final Folder _folder;

  // Mock notes data grouped by date
  final List<_DateGroup> _noteGroups = [];

  @override
  void initState() {
    super.initState();
    _initMockData();
  }

  void _initMockData() {
    // Mock folder based on ID
    _folder = Folder(
      id: widget.folderId,
      name: 'Работа',
      description: 'Рабочие заметки и митинги',
      color: AppColors.folderColors[2],
      icon: Icons.work,
      notesCount: 15,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    _noteGroups.addAll([
      _DateGroup(
        label: 'Сегодня',
        notes: [
          Note(
            id: '1',
            text:
                'Обсудили план на следующий спринт. Нужно добавить новый '
                'функционал для авторизации и интеграцию с внешним API.',
            createdAt: now.subtract(const Duration(hours: 1)),
            duration: const Duration(seconds: 45),
            modelName: 'Whisper Small',
            language: 'Русский',
            wordCount: 18,
            tags: ['работа', 'спринт'],
          ),
          Note(
            id: '2',
            text:
                'Записка о встрече с клиентом. Нужно подготовить '
                'презентацию до пятницы.',
            createdAt: now.subtract(const Duration(hours: 3)),
            duration: const Duration(seconds: 32),
            modelName: 'Whisper Small',
            language: 'Русский',
            wordCount: 11,
            tags: ['клиент', 'презентация'],
          ),
        ],
      ),
      _DateGroup(
        label: 'Вчера',
        notes: [
          Note(
            id: '3',
            text:
                'Идея для нового проекта: приложение для трекинга привычек '
                'с геймификацией.',
            createdAt: yesterday.subtract(const Duration(hours: 5)),
            duration: const Duration(seconds: 28),
            modelName: 'Whisper Small',
            language: 'Русский',
            wordCount: 10,
            tags: ['идея'],
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
              child: Icon(_folder.icon, color: _folder.color, size: 18),
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
      body: Stack(
        children: [
          ListView(
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
          Positioned(
            left: AppSizes.screenPadding,
            right: AppSizes.screenPadding,
            bottom: context.padding.bottom + AppSizes.p16,
            child: RecordingInput(
              state: _recordingState,
              recordingDuration: _recordingDuration,
              onStartRecording: _onStartRecording,
              onStopRecording: _onStopRecording,
              onCancelRecording: _onCancelRecording,
              onUploadFile: _onUploadFile,
            ),
          ),
        ],
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

  void _onNoteTap(Note note) {
    context.go('/folders/${widget.folderId}/note/${note.id}');
  }

  void _onCopyNote(Note note) {
    // TODO: Copy to clipboard
  }

  void _onShareNote(Note note) {
    // TODO: Share note
  }

  void _onStartRecording() {
    setState(() => _recordingState = RecordingState.recording);
    // TODO: Start actual recording
  }

  void _onStopRecording() {
    setState(() => _recordingState = RecordingState.transcribing);
    // TODO: Stop recording and start transcription

    // Simulate transcription complete after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _recordingState = RecordingState.idle);
      }
    });
  }

  void _onCancelRecording() {
    setState(() {
      _recordingState = RecordingState.idle;
      _recordingDuration = Duration.zero;
    });
  }

  void _onUploadFile() {
    // TODO: Open file picker
  }
}

class _DateGroup {
  final String label;
  final List<Note> notes;

  const _DateGroup({required this.label, required this.notes});
}
