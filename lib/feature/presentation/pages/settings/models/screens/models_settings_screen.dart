import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/adaptive/window/adaptive_content_width.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/constants/app_spacer.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/state/async/async_state.dart';
import 'package:voice_notes/core/state/async/async_state_widgets.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/logic/models_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/widgets/models_settings_model_card.dart';
import 'package:voice_notes/feature/presentation/widgets/dialogs/error_dialog.dart';

class ModelsSettingsScreen extends StatelessWidget {
  static const double _modelCardContentMaxWidth = 760;

  const ModelsSettingsScreen({super.key});

  static void go(BuildContext context) {
    context.go(AppRoutes.settings.models);
  }

  void _handleStateChanges(
    BuildContext context,
    AsyncState<ModelsState> baseState,
  ) {
    if (baseState is! AsyncSuccess<ModelsState>) return;
    final state = baseState.data;

    for (final entry in state.downloads.entries) {
      final progress = entry.value;
      if (progress.status.isFailed && progress.errorMessage != null) {
        _showErrorDialog(context, progress.errorMessage!);
        break;
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => ErrorDialog(
        title: context.l10n.settingsDownloadError,
        message: message,
        icon: Icons.error_outline_rounded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStateBody<ModelsCubit, ModelsState>(
      buildAlways: true,
      listener: _handleStateChanges,
      onSuccess: (context, state) {
        final l10n = context.l10n;
        final models = state.models;

        if (models.isEmpty) return Center(child: Text(l10n.stateEmpty));

        final activeModel = state.selectedModel;
        final otherModels = [
          for (final model in models)
            if (!model.isSelected) model,
        ];

        return Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: AdaptiveContentWidth(
            maxWidth: _modelCardContentMaxWidth,
            child: CustomScrollView(
              slivers: [
                if (activeModel != null)
                  _ModelCardSectionSliver(
                    title: l10n.settingsActiveModel,
                    child: ModelsSettingsModelCard(
                      state: state,
                      model: activeModel,
                    ),
                  ),

                if (otherModels.isNotEmpty)
                  _AvailableModelsSection(models: otherModels, state: state),
                const SliverToBoxAdapter(child: AppSpacer.p40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvailableModelsSection extends StatelessWidget {
  final List<AsrModelEntity> models;
  final ModelsState state;

  const _AvailableModelsSection({required this.models, required this.state});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: AppSpacer.p24),
        SliverToBoxAdapter(
          child: _SectionTitle(title: context.l10n.settingsAvailableModels),
        ),
        const SliverToBoxAdapter(child: AppSpacer.p8),
        SliverList.separated(
          itemCount: models.length,
          itemBuilder: (context, index) =>
              ModelsSettingsModelCard(state: state, model: models[index]),
          separatorBuilder: (_, _) => AppSpacer.p12,
        ),
      ],
    );
  }
}

class _ModelCardSectionSliver extends StatelessWidget {
  final String title;
  final Widget child;

  const _ModelCardSectionSliver({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSizes.p8,
        children: [
          _SectionTitle(title: title),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.overline.copyWith(
        color: context.themeColors.textTertiary,
      ),
    );
  }
}
