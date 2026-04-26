part of 'model_card.dart';

class _SelectedModelButton extends StatelessWidget {
  const _SelectedModelButton();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final asrStatus = context.select((AsrCubit cubit) => cubit.state.status);
    final l10n = context.l10n;

    return switch (asrStatus) {
      Status.loading => OutlinedButton.icon(
        onPressed: null,
        icon: SizedBox.square(
          dimension: AppSizes.p14,
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.strokeThin,
            color: themeColors.textTertiary,
          ),
        ),
        label: Text(l10n.asrInitializing, textAlign: TextAlign.center),
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.textTertiary,
          side: BorderSide(color: themeColors.borderPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
      Status.error => OutlinedButton.icon(
        onPressed: context.read<AsrCubit>().retry,
        icon: const Icon(Icons.refresh, size: AppSizes.iconMedium),
        label: Text(l10n.asrReinitialize),
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.error,
          side: BorderSide(color: themeColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
      _ => OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: themeColors.textTertiary,
          side: BorderSide(color: themeColors.borderPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
        child: Text(l10n.modelActionInUse),
      ),
    };
  }
}
