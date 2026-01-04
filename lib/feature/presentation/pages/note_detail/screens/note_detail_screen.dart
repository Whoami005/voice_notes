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
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_detail_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/chips/tag_chip.dart';
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
    final textTheme = context.textTheme;

    return BaseStateBody<NoteDetailCubit, NoteDetailData>(
      buildWhen: (prev, curr) => prev != curr,
      listener: _stateListener,
      onSuccess: (context, data) {
        // Sync text controller when note changes (not during editing)
        if (!data.isEditing && _textController.text != data.note.text) {
          _textController.text = data.note.text;
        }

        return Scaffold(
          backgroundColor: themeColors.bgPrimary,
          appBar: AppBar(
            backgroundColor: themeColors.bgPrimary,
            surfaceTintColor: Colors.transparent,
            title: Text('Заметка', style: textTheme.titleLarge),
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
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            children: [
              const _SectionHeader(title: 'Текст'),
              AppSpacer.p12,
              _TextSection(
                text: data.note.text,
                controller: _textController,
                isEditing: data.isEditing,
              ),
              AppSpacer.p24,
              const _SectionHeader(title: 'Теги'),
              AppSpacer.p12,
              _TagsSection(
                tags: data.note.tags,
                isEditing: data.isEditing,
                tagController: _tagController,
                onAddTag: () => _onAddTag(context),
                onRemoveTag: (tag) => _onRemoveTag(context, tag),
              ),
              AppSpacer.p24,
              const _SectionHeader(title: 'Информация'),
              AppSpacer.p12,
              _InfoSection(note: data.note),
              AppSpacer.p24,
              const _SectionHeader(title: 'Действия'),
              AppSpacer.p12,
              _ActionsSection(
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Text(
      title,
      style: AppTypography.overline.copyWith(color: themeColors.textSecondary),
    );
  }
}

class _TextSection extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  final bool isEditing;

  const _TextSection({
    required this.text,
    required this.controller,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    if (isEditing) {
      return TextField(
        controller: controller,
        maxLines: null,
        minLines: 4,
        style: textTheme.bodyMedium?.copyWith(
          color: themeColors.textPrimary,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Введите текст заметки...',
          filled: true,
          fillColor: themeColors.bgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            borderSide: BorderSide(color: themeColors.borderPrimary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            borderSide: BorderSide(color: themeColors.borderPrimary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            borderSide: BorderSide(color: themeColors.accentPrimary),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: Text(
        text,
        style: textTheme.bodyMedium?.copyWith(
          color: themeColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  final List<TagEntity> tags;
  final bool isEditing;
  final TextEditingController tagController;
  final VoidCallback onAddTag;
  final ValueChanged<TagEntity> onRemoveTag;

  const _TagsSection({
    required this.tags,
    required this.isEditing,
    required this.tagController,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Column(
      spacing: AppSizes.p12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: [
            for (final tag in tags)
              TagChip(
                label: tag.name,
                onDelete: isEditing ? () => onRemoveTag(tag) : null,
              ),
          ],
        ),
        if (isEditing)
          Row(
            spacing: AppSizes.p8,
            children: [
              Expanded(
                child: TextField(
                  controller: tagController,
                  decoration: const InputDecoration(
                    hintText: 'Новый тег...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSizes.p12,
                      vertical: AppSizes.p10,
                    ),
                  ),
                  onSubmitted: (_) => onAddTag(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: themeColors.accentPrimary),
                onPressed: onAddTag,
              ),
            ],
          ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final NoteEntity note;

  const _InfoSection({required this.note});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: themeColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: themeColors.borderPrimary),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.timer_outlined,
            label: 'Длительность',
            value: _formatDuration(note.duration),
          ),
          _Divider(),
          _InfoRow(icon: Icons.language, label: 'Язык', value: note.language),
          _Divider(),
          _InfoRow(icon: Icons.memory, label: 'Модель', value: note.modelName),
          _Divider(),
          _InfoRow(
            icon: Icons.text_fields,
            label: 'Слов',
            value: '${note.wordCount}',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Дата',
            value: _formatDate(note.createdAt),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _getMonthName(date.month);
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  String _getMonthName(int month) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return months[month - 1];
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.iconMedium,
            color: themeColors.textTertiary,
          ),
          AppSpacer.p12,
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: themeColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: themeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    return Divider(color: themeColors.borderPrimary, height: 1);
  }
}

class _ActionsSection extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onRetranscribe;
  final VoidCallback onDelete;

  const _ActionsSection({
    required this.onCopy,
    required this.onShare,
    required this.onRetranscribe,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Column(
      children: [
        _ActionButton(
          icon: Icons.copy_outlined,
          label: 'Копировать текст',
          onTap: onCopy,
        ),
        AppSpacer.p8,
        _ActionButton(
          icon: Icons.share_outlined,
          label: 'Поделиться',
          onTap: onShare,
        ),
        AppSpacer.p8,
        _ActionButton(
          icon: Icons.refresh,
          label: 'Перетранскрибировать',
          onTap: onRetranscribe,
        ),
        AppSpacer.p8,
        _ActionButton(
          icon: Icons.delete_outline,
          label: 'Удалить заметку',
          color: themeColors.error,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final textTheme = context.textTheme;
    final buttonColor = color ?? themeColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: themeColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: themeColors.borderPrimary),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppSizes.iconMedium, color: buttonColor),
            AppSpacer.p12,
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: buttonColor),
            ),
          ],
        ),
      ),
    );
  }
}
