import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/status/status_state_widgets.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_search/components/folder_search_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/folder_search/components/folder_search_results_section.dart';
import 'package:voice_notes/feature/presentation/pages/folder_search/logic/folder_search_cubit.dart';

/// Dedicated fullscreen route for searching folders.
class FolderSearchScreen extends StatefulWidget implements AppRouteWrapper {
  const FolderSearchScreen({super.key});

  static void go(BuildContext context) {
    context.push(AppRoutes.folders.search);
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (_) => FolderSearchCubit(repository: getIt<FolderRepository>()),
      child: this,
    );
  }

  @override
  State<FolderSearchScreen> createState() => _FolderSearchScreenState();
}

class _FolderSearchScreenState extends State<FolderSearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;

    setState(() {
      context.read<FolderSearchCubit>().search(_controller.text);
    });
  }

  void _onClear() {
    _controller.clear();
    context.read<FolderSearchCubit>().clearSearch();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StatusStateBody<FolderSearchCubit, FolderSearchState>(
        onSuccess: (context, _) {
          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                FolderSearchAppBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  onClear: _onClear,
                ),
                const FolderSearchResultsSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}
