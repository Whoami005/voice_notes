import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/extensions/context_extensions.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
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

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;

    return Scaffold(
      backgroundColor: themeColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: themeColors.bgPrimary,
        surfaceTintColor: Colors.transparent,
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
