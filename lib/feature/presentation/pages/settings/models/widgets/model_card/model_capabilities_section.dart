part of 'model_card.dart';

class _ModelCapabilitiesSection extends StatelessWidget {
  final AsrModelEntity model;

  const _ModelCapabilitiesSection({required this.model});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSizes.p8,
      children: [
        Text(
          l10n.modelCapabilitiesTitle,
          style: AppTypography.micro.copyWith(
            color: themeColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p6,
          children: [
            _CapabilityChip(
              key: const Key('model-card-capability-realtime'),
              icon: Icons.speed,
              label: l10n.modelCapabilityRealTimeProgress,
            ),
            _CapabilityChip(
              key: const Key('model-card-capability-cancelable'),
              icon: Icons.cancel_outlined,
              label: l10n.modelCapabilityCancelable,
            ),
            _CapabilityChip(
              key: const Key('model-card-capability-partial-text'),
              icon: Icons.text_snippet_outlined,
              label: l10n.modelCapabilityLivePartialText,
            ),
          ],
        ),
      ],
    );
  }
}
