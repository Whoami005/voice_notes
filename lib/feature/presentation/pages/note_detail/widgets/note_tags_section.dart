import 'package:flutter/material.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';
import 'package:voice_notes/feature/presentation/widgets/chips/tag_chip.dart';

class NoteTagsSection extends StatelessWidget {
  final List<TagEntity> tags;
  final bool isEditing;
  final TextEditingController tagController;
  final VoidCallback onAddTag;
  final ValueChanged<TagEntity> onRemoveTag;

  const NoteTagsSection({
    required this.tags,
    required this.isEditing,
    required this.tagController,
    required this.onAddTag,
    required this.onRemoveTag,
    super.key,
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
