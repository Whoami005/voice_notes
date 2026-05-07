import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/theme/app_colors.dart';
import 'package:voice_notes/core/theme/app_typography.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/logic/models_cubit.dart';

class SettingsShellScreen extends StatefulWidget implements AppRouteWrapper {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  const SettingsShellScreen({
    required this.navigationShell,
    required this.children,
    super.key,
  });

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => ModelsCubit(repository: getIt<ModelRepository>()),
      child: this,
    );
  }

  @override
  State<SettingsShellScreen> createState() => _SettingsShellScreenState();
}

class _SettingsShellScreenState extends State<SettingsShellScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.children.length,
      initialIndex: widget.navigationShell.currentIndex,
      vsync: this,
    );
    _tabController.addListener(_switchedTab);
  }

  @override
  void didUpdateWidget(covariant SettingsShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tabController.index = widget.navigationShell.currentIndex;
  }

  void _switchedTab() {
    final currentIndex = widget.navigationShell.currentIndex;

    if (_tabController.index == currentIndex) return;

    widget.navigationShell.goBranch(_tabController.index);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_switchedTab)
      ..dispose();
    super.dispose();
  }

  // void _switchBranch(int index) {
  //   if (index == widget.navigationShell.currentIndex) return;
  //
  //   widget.navigationShell.goBranch(index);
  // }

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: themeColors.bgPrimary,
        surfaceTintColor: AppColors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          context.l10n.settingsTitle,
          style: AppTypography.h2.copyWith(color: themeColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.settingsTabGeneral),
            Tab(text: context.l10n.settingsTabModels),
          ],
        ),
      ),
      body: TabBarView(controller: _tabController, children: widget.children),
    );
  }
}

// class _SettingsDesktopSwitcher extends StatelessWidget {
//   final int currentIndex;
//   final ValueChanged<int> onSelected;
//
//   const _SettingsDesktopSwitcher({
//     required this.currentIndex,
//     required this.onSelected,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final themeColors = context.themeColors;
//     final labels = [
//       context.l10n.settingsTabGeneral,
//       context.l10n.settingsTabModels,
//     ];
//
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSizes.screenPadding,
//         vertical: AppSizes.p4,
//       ),
//       constraints: const BoxConstraints(maxWidth: 320),
//       decoration: BoxDecoration(
//         color: themeColors.bgSecondary,
//         borderRadius: BorderRadius.circular(AppSizes.radiusXL),
//         border: Border.all(color: themeColors.borderPrimary),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(AppSizes.p6),
//         child: Row(
//           spacing: AppSizes.p8,
//           children: [
//             for (var index = 0; index < labels.length; index++)
//               Expanded(
//                 child: _SettingsDesktopSwitchButton(
//                   label: labels[index],
//                   isSelected: currentIndex == index,
//                   onTap: () => onSelected(index),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SettingsDesktopSwitchButton extends StatelessWidget {
//   final String label;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   const _SettingsDesktopSwitchButton({
//     required this.label,
//     required this.isSelected,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final themeColors = context.themeColors;
//     final backgroundColor = isSelected
//         ? themeColors.accentPrimary.withValues(alpha: 0.14)
//         : AppColors.transparent;
//     final foregroundColor = isSelected
//         ? themeColors.textPrimary
//         : themeColors.textSecondary;
//
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 180),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
//       ),
//       child: TextButton(
//         onPressed: onTap,
//         style: TextButton.styleFrom(
//           foregroundColor: foregroundColor,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
//           ),
//           padding: const EdgeInsets.symmetric(
//             horizontal: AppSizes.p16,
//             vertical: AppSizes.p10,
//           ),
//         ),
//         child: Text(label, textAlign: TextAlign.center),
//       ),
//     );
//   }
// }
