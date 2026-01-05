import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/presentation/widgets/chips/tag_chip.dart';

class NoteTagsSection extends StatefulWidget {
  final List<TagEntity> tags;
  final bool isEditing;
  final ValueChanged<String> onAddTag;
  final ValueChanged<TagEntity> onRemoveTag;

  const NoteTagsSection({
    required this.tags,
    required this.isEditing,
    required this.onAddTag,
    required this.onRemoveTag,
    super.key,
  });

  @override
  State<NoteTagsSection> createState() => _NoteTagsSectionState();
}

class _NoteTagsSectionState extends State<NoteTagsSection> {
  late TextEditingController _tagController;

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _onAddTag() {
    final tagName = _tagController.text.trim();
    if (tagName.isNotEmpty) {
      widget.onAddTag(tagName);
      _tagController.clear();
    }
  }

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
            for (final tag in widget.tags)
              TagChip(
                label: tag.name,
                onDelete: widget.isEditing ? () => widget.onRemoveTag(tag) : null,
              ),
          ],
        ),
        if (widget.isEditing)
          Row(
            spacing: AppSizes.p8,
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: 'Новый тег...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSizes.p12,
                      vertical: AppSizes.p10,
                    ),
                  ),
                  onSubmitted: (_) => _onAddTag(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: themeColors.accentPrimary),
                onPressed: _onAddTag,
              ),
            ],
          ),
      ],
    );
  }
}
