import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/note.dart';
import 'package:voice_notes/feature/presentation/widgets/chips/tag_chip.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/confirm_dialog.dart';

class NoteDetailScreen extends StatefulWidget {
  final String folderId;
  final String noteId;

  const NoteDetailScreen({
    required this.folderId,
    required this.noteId,
    super.key,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _textController;
  late TextEditingController _tagController;
  late Note _note;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _initMockData();
    _textController = TextEditingController(text: _note.text);
    _tagController = TextEditingController();
  }

  void _initMockData() {
    // Mock note data based on ID
    _note = Note(
      id: widget.noteId,
      text:
          'Обсудили план на следующий спринт. Нужно добавить новый '
          'функционал для авторизации и интеграцию с внешним API.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      duration: const Duration(seconds: 45),
      modelName: 'Whisper Small',
      language: 'Русский',
      wordCount: 18,
      tags: ['работа', 'спринт'],
    );
    _tags = List.from(_note.tags);
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

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: themeColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Заметка', style: textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit_outlined,
              color: _isEditing
                  ? themeColors.accentPrimary
                  : themeColors.textSecondary,
            ),
            onPressed: _toggleEditing,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Текст'),
            AppSpacer.p12,
            _TextSection(
              text: _note.text,
              controller: _textController,
              isEditing: _isEditing,
            ),
            AppSpacer.p24,
            const _SectionHeader(title: 'Теги'),
            AppSpacer.p12,
            _TagsSection(
              tags: _tags,
              isEditing: _isEditing,
              tagController: _tagController,
              onAddTag: _onAddTag,
              onRemoveTag: _onRemoveTag,
            ),
            AppSpacer.p24,
            const _SectionHeader(title: 'Информация'),
            AppSpacer.p12,
            _InfoSection(note: _note),
            AppSpacer.p24,
            const _SectionHeader(title: 'Действия'),
            AppSpacer.p12,
            _ActionsSection(
              onCopy: _onCopy,
              onShare: _onShare,
              onRetranscribe: _onRetranscribe,
              onDelete: _onDelete,
            ),
            AppSpacer.p32,
          ],
        ),
      ),
    );
  }

  void _toggleEditing() {
    if (_isEditing) {
      // Save changes
      setState(() {
        _note = _note.copyWith(
          text: _textController.text,
          tags: List.from(_tags),
        );
        _isEditing = false;
      });
    } else {
      setState(() => _isEditing = true);
    }
  }

  void _onAddTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _onRemoveTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _onCopy() async {
    final c = context;

    await Clipboard.setData(ClipboardData(text: _note.text));
    if (!c.mounted) return;

    ScaffoldMessenger.of(c).showSnackBar(
      const SnackBar(content: Text('Текст скопирован')),
    );
  }

  void _onShare() {
    // TODO: Implement share
  }

  void _onRetranscribe() {
    // TODO: Implement retranscribe
  }

  Future<void> _onDelete() async {
    final themeColors = context.themeColors;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Удалить заметку?',
      message: 'Это действие нельзя отменить.',
      confirmText: 'Удалить',
      confirmColor: themeColors.error,
    );

    if ((confirmed ?? false) && mounted) context.pop();
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
      style: AppTypography.overline.copyWith(
        color: themeColors.textSecondary,
      ),
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
  final List<String> tags;
  final bool isEditing;
  final TextEditingController tagController;
  final VoidCallback onAddTag;
  final ValueChanged<String> onRemoveTag;

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: tags.map((tag) {
            return TagChip(
              label: tag,
              onDelete: isEditing ? () => onRemoveTag(tag) : null,
            );
          }).toList(),
        ),
        if (isEditing) ...[
          AppSpacer.p12,
          Row(
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
              AppSpacer.p8,
              IconButton(
                icon: Icon(Icons.add_circle, color: themeColors.accentPrimary),
                onPressed: onAddTag,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Note note;

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
          _InfoRow(
            icon: Icons.language,
            label: 'Язык',
            value: note.language,
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.memory,
            label: 'Модель',
            value: note.modelName,
          ),
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
