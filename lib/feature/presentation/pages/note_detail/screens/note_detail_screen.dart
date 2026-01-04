import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/state.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_actions_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_info_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_tags_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/note_text_section.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/widgets/section_header.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';

class NoteDetailScreen extends StatefulWidget implements AppRouteWrapper {
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

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _textController;
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return BaseStateScaffold<NoteDetailCubit, NoteDetailData>(
      title: 'Заметка',
      buildWhen: (prev, curr) => prev != curr,
      listener: _stateListener,
      onSuccess: (context, data) {
        if (!data.isEditing && _textController.text != data.note.text) {
          _textController.text = data.note.text;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Заметка'),
            actionsPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
            actions: [
              IconButton(
                icon: Icon(
                  data.isEditing ? Icons.check : Icons.edit_outlined,
                  color: data.isEditing
                      ? themeColors.accentPrimary
                      : themeColors.textSecondary,
                ),
                onPressed: () => _toggleEditing(context, data),
              ),
            ],
          ),
          body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            children: [
              const SectionHeader(title: 'Текст'),
              AppSpacer.p12,
              NoteTextSection(
                text: data.note.text,
                controller: _textController,
                isEditing: data.isEditing,
              ),
              AppSpacer.p24,
              const SectionHeader(title: 'Теги'),
              AppSpacer.p12,
              NoteTagsSection(
                tags: data.note.tags,
                isEditing: data.isEditing,
                tagController: _tagController,
                onAddTag: () => _onAddTag(context),
                onRemoveTag: (tag) => _onRemoveTag(context, tag),
              ),
              AppSpacer.p24,
              const SectionHeader(title: 'Информация'),
              AppSpacer.p12,
              NoteInfoSection(note: data.note),
              AppSpacer.p24,
              const SectionHeader(title: 'Действия'),
              AppSpacer.p12,
              NoteActionsSection(
                onCopy: () => _onCopy(data.note),
                onShare: _onShare,
                onRetranscribe: _onRetranscribe,
                onDelete: () => _onDelete(context),
              ),
              AppSpacer.p32,
            ],
          ),
        );
      },
    );
  }

  void _stateListener(BuildContext context, BaseState<NoteDetailData> state) {
    if (state is ErrorState<NoteDetailData>) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.failure.message)));
    }
  }

  void _toggleEditing(BuildContext context, NoteDetailData data) {
    final cubit = context.read<NoteDetailCubit>();

    data.isEditing
        ? cubit.updateNote(text: _textController.text)
        : cubit.toggleEditing();
  }

  void _onAddTag(BuildContext context) {
    final tagName = _tagController.text.trim();

    if (tagName.isNotEmpty) {
      context.read<NoteDetailCubit>().addTag(tagName);
      _tagController.clear();
    }
  }

  void _onRemoveTag(BuildContext context, TagEntity tag) {
    context.read<NoteDetailCubit>().removeTag(tag);
  }

  Future<void> _onCopy(NoteEntity note) async {
    await Clipboard.setData(ClipboardData(text: note.text));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Текст скопирован')));
  }

  void _onShare() {
    // TODO: Implement share
  }

  void _onRetranscribe() {
    // TODO: Implement retranscribe
  }

  Future<void> _onDelete(BuildContext context) async {
    final cubit = context.read<NoteDetailCubit>();

    final themeColors = context.themeColors;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Удалить заметку?',
      message: 'Это действие нельзя отменить.',
      confirmText: 'Удалить',
      confirmColor: themeColors.error,
    );

    if (confirmed ?? false) {
      final deleted = await cubit.deleteNote();
      if (deleted && context.mounted) context.pop();
    }
  }
}
