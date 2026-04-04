import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/constants/app_sizes.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/screens/models_settings_screen.dart';
import 'package:voice_notes/feature/presentation/widgets/conditional/conditional_wrapper.dart';

/// Баннер статуса ASR сервиса.
///
/// Показывается под AppBar при загрузке или ошибке инициализации модели.
/// Аналог индикатора подключения в мессенджерах.
class AsrStatusBanner extends StatelessWidget {
  final bool isSliver;

  const AsrStatusBanner({super.key}) : isSliver = false;

  const AsrStatusBanner.sliver({super.key}) : isSliver = true;

  @override
  Widget build(BuildContext context) {
    final state = context.select(
      (AsrCubit c) => (status: c.state.status, hasModel: c.state.hasModel),
    );

    return ConditionalWrapper(
      condition: isSliver,
      onAddWrapper: (child) => SliverToBoxAdapter(child: child),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: switch (state) {
          (status: Status.loading, hasModel: _) => const _LoadingBanner(),
          (status: Status.error, hasModel: _) => const _ErrorBanner(),
          (status: Status.success, hasModel: false) => const _NoModelBanner(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return ListTile(
      visualDensity: VisualDensity.compact,
      tileColor: themeColors.info.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
      ),
      leading: SizedBox.square(
        dimension: AppSizes.iconSmall,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: themeColors.info,
        ),
      ),
      title: Text(
        context.l10n.asrInitializing,
        style: AppTypography.caption.copyWith(color: themeColors.info),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return ListTile(
      splashColor: AppColors.transparent,
      onTap: context.read<AsrCubit>().retry,
      visualDensity: VisualDensity.compact,
      tileColor: themeColors.error.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
      ),
      leading: Icon(
        Icons.error_outline,
        size: AppSizes.iconSmall,
        color: themeColors.error,
      ),
      title: Text(
        context.l10n.asrInitError,
        style: AppTypography.caption.copyWith(color: themeColors.error),
      ),
      trailing: Icon(
        Icons.refresh,
        size: AppSizes.iconMedium,
        color: themeColors.error,
      ),
    );
  }
}

class _NoModelBanner extends StatelessWidget {
  const _NoModelBanner();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return ListTile(
      onTap: () => ModelsSettingsScreen.go(context),
      visualDensity: VisualDensity.compact,
      tileColor: themeColors.warning.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
      ),
      leading: Icon(
        Icons.model_training,
        size: AppSizes.iconSmall,
        color: themeColors.warning,
      ),
      title: Text(
        context.l10n.asrNoModel,
        style: AppTypography.caption.copyWith(color: themeColors.warning),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: AppSizes.iconMedium,
        color: themeColors.warning,
      ),
    );
  }
}
