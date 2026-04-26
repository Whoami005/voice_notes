part of 'model_card.dart';

class _ModelActionButtons extends StatelessWidget {
  final AsrModelEntity model;
  final VoidCallback? onUse;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const _ModelActionButtons({
    required this.model,
    this.onUse,
    this.onDownload,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    if (!model.isDownloaded) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download, size: AppSizes.iconMedium),
          label: Text(context.l10n.modelActionDownload),
          style: OutlinedButton.styleFrom(
            foregroundColor: themeColors.accentPrimary,
            side: BorderSide(color: themeColors.accentPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            ),
          ),
        ),
      );
    }

    return Row(
      spacing: AppSizes.p8,
      children: [
        Expanded(
          child: model.isSelected
              ? const _SelectedModelButton()
              : ElevatedButton(
                  onPressed: onUse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColors.accentPrimary,
                    foregroundColor: themeColors.textInverse,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.buttonRadius,
                      ),
                    ),
                  ),
                  child: Text(context.l10n.modelActionUse),
                ),
        ),
        IconButton(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            color: themeColors.error,
            size: AppSizes.iconLarge,
          ),
          style: IconButton.styleFrom(
            backgroundColor: themeColors.error.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
            ),
          ),
        ),
      ],
    );
  }
}
