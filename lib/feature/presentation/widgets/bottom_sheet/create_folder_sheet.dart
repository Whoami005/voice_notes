import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:voice_notes/feature/presentation/widgets/folder_icon_badge.dart';

class CreateFolderResult {
  final String name;
  final String? description;
  final Color color;
  final IconRefEntity icon;

  const CreateFolderResult({
    required this.name,
    required this.color,
    required this.icon,
    this.description,
  });
}

class CreateFolderSheet extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final Color? initialColor;
  final IconRefEntity? initialIcon;

  const CreateFolderSheet({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialColor,
    this.initialIcon,
  });

  static Future<CreateFolderResult?> show({
    required BuildContext context,
    String? initialName,
    String? initialDescription,
    Color? initialColor,
    IconRefEntity? initialIcon,
  }) {
    return AppBottomSheet.show<CreateFolderResult>(
      context: context,
      useRootNavigator: true,
      child: CreateFolderSheet(
        initialName: initialName,
        initialDescription: initialDescription,
        initialColor: initialColor,
        initialIcon: initialIcon,
      ),
    );
  }

  @override
  State<CreateFolderSheet> createState() => _CreateFolderSheetState();
}

class _CreateFolderSheetState extends State<CreateFolderSheet> {
  static const List<IconRefEntity> _folderIcons = [
    MaterialIconRefEntity.folder,
    MaterialIconRefEntity.work,
    MaterialIconRefEntity.book,
    MaterialIconRefEntity.star,
    MaterialIconRefEntity.favorite,
    MaterialIconRefEntity.musicNote,
    MaterialIconRefEntity.cameraAlt,
    MaterialIconRefEntity.code,
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late Color _selectedColor;
  late IconRefEntity _selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _selectedColor = widget.initialColor ?? AppColors.folderColors.first;
    _selectedIcon = widget.initialIcon ?? _folderIcons.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    context.pop(
      CreateFolderResult(
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final isEditing = widget.initialName != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEditing
              ? context.l10n.editFolderTitle
              : context.l10n.createFolderTitle,
          style: textTheme.headlineMedium,
        ),
        AppSpacer.p20,
        _PreviewCard(
          name: _nameController.text.isEmpty
              ? context.l10n.createFolderNamePreview
              : _nameController.text,
          color: _selectedColor,
          icon: _selectedIcon,
        ),
        AppSpacer.p20,
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.l10n.createFolderNameHint,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        AppSpacer.p12,
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: context.l10n.createFolderDescriptionHint,
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          minLines: 1,
        ),
        AppSpacer.p20,
        Text(context.l10n.createFolderColorLabel, style: textTheme.labelMedium),
        AppSpacer.p12,
        _ColorPicker(
          colors: AppColors.folderColors,
          selected: _selectedColor,
          onSelect: (color) => setState(() => _selectedColor = color),
        ),
        AppSpacer.p20,
        Text(context.l10n.createFolderIconLabel, style: textTheme.labelMedium),
        AppSpacer.p12,
        _IconPicker(
          icons: _folderIcons,
          selected: _selectedIcon,
          selectedColor: _selectedColor,
          onSelect: (icon) => setState(() => _selectedIcon = icon),
        ),
        AppSpacer.p24,
        ElevatedButton(
          onPressed: _nameController.text.trim().isEmpty ? null : _submit,
          child: Text(
            isEditing
                ? context.l10n.createFolderButtonSave
                : context.l10n.createFolderButtonCreate,
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String name;
  final Color color;
  final IconRefEntity icon;

  const _PreviewCard({
    required this.name,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final themeColors = context.themeColors;

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: themeColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        children: [
          FolderIconBadge(
            icon: icon,
            color: color,
            size: AppSizes.avatarLarge,
            iconSize: AppSizes.iconLarge,
            borderRadius: AppSizes.p14,
          ),
          AppSpacer.p14,
          Expanded(
            child: Text(
              name,
              style: textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;

  const _ColorPicker({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Wrap(
      spacing: AppSizes.p12,
      runSpacing: AppSizes.p12,
      children: List.generate(colors.length, (index) {
        final color = colors[index];

        final isSelected = color == selected;

        return GestureDetector(
          onTap: () => onSelect(color),
          child: Container(
            width: AppSizes.avatarMedium,
            height: AppSizes.avatarMedium,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: isSelected
                  ? Border.all(color: themeColors.textPrimary, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final List<IconRefEntity> icons;
  final IconRefEntity selected;
  final Color selectedColor;
  final ValueChanged<IconRefEntity> onSelect;

  const _IconPicker({
    required this.icons,
    required this.selected,
    required this.selectedColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Wrap(
      spacing: AppSizes.p10,
      runSpacing: AppSizes.p10,
      children: List.generate(icons.length, (index) {
        final icon = icons[index];
        final isSelected = icon == selected;

        return GestureDetector(
          onTap: () => onSelect(icon),
          child: Container(
            width: AppSizes.avatarLarge,
            height: AppSizes.avatarLarge,
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor.withValues(alpha: 0.15)
                  : themeColors.bgTertiary,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: isSelected
                  ? Border.all(color: selectedColor, width: 2)
                  : null,
            ),
            child: FolderIconBadge(
              icon: icon,
              color: isSelected ? selectedColor : themeColors.textSecondary,
              size: AppSizes.avatarLarge,
              iconSize: AppSizes.iconLarge,
              borderRadius: AppSizes.radiusMedium,
              backgroundColor: Colors.transparent,
            ),
          ),
        );
      }),
    );
  }
}
