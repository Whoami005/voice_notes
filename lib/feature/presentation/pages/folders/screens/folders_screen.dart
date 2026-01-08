import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_route_wrapper.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/state/state.dart';
import 'package:voice_notes/feature/domain/repositories/folder_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folders/components/folders_app_bar.dart';
import 'package:voice_notes/feature/presentation/pages/folders/components/folders_list_section.dart';
import 'package:voice_notes/feature/presentation/pages/folders/logic/folders_cubit.dart';
import 'package:voice_notes/feature/presentation/pages/folders/widgets/voice_record_button.dart';
import 'package:voice_notes/feature/presentation/widgets/refresh/refreshable_wrapper.dart';

class FoldersScreen extends StatefulWidget implements AppRouteWrapper {
  const FoldersScreen({super.key});

  /// Навигация на главный экран папок
  static void go(BuildContext context) {
    context.go(AppRoutes.folders.root);
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return BlocProvider(
      create: (context) => FoldersCubit(repository: getIt<FolderRepository>()),
      child: this,
    );
  }

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  @override
  Widget build(BuildContext context) {
    return BaseStateScaffold<FoldersCubit, FoldersState>(
      title: 'Заметки',
      onSuccess: (context, state) {
        return const Scaffold(
          floatingActionButton: VoiceRecordButton(),
          body: SafeArea(
            bottom: false,
            child: RefreshableWrapper<FoldersCubit>(
              child: CustomScrollView(
                slivers: [FoldersAppBar(), FoldersListSection()],
              ),
            ),
          ),
        );
      },
    );
  }
}
