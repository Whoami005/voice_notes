import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_restoration_ids.dart';
import 'package:voice_notes/core/packages/app_router/app_router.dart';
import 'package:voice_notes/core/packages/app_router/route_builder.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_route_names.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/screens/folder_detail_screen.dart';
import 'package:voice_notes/feature/presentation/pages/folder_search/screens/folder_search_screen.dart';
import 'package:voice_notes/feature/presentation/pages/folders/screens/folders_adaptive_scaffold.dart';
import 'package:voice_notes/feature/presentation/pages/folders/screens/folders_screen.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/screens/note_detail_screen.dart';

/// Route module для ветки Folders.
///
/// Содержит конфигурацию роутов для:
/// - /folders (список папок)
/// - /folders/search (полноэкранный поиск)
/// - /folders/:id (детали папки)
/// - /folders/:id/note/:noteId (детали заметки)
class FoldersRouteModule {
  const FoldersRouteModule._();

  /// Создаёт ветку навигации для Folders
  static StatefulShellBranch branch() => StatefulShellBranch(
    navigatorKey: AppRouter.foldersBranchNavigatorKey,
    restorationScopeId: AppRestorationIds.foldersBranch,
    initialLocation: AppRoutes.folders.root,
    routes: [_foldersShellRoute],
  );

  static ShellRoute get _foldersShellRoute => ShellRoute(
    navigatorKey: AppRouter.detailPaneNavigatorKey,
    restorationScopeId: AppRestorationIds.foldersPaneShell,
    builder: (context, state, child) =>
        wrapRoute(context, FoldersAdaptiveScaffold(child: child)),
    routes: [_rootRoute],
  );

  static GoRoute get _rootRoute => GoRoute(
    name: AppRouteNames.folders.root,
    path: AppRoutes.folders.pattern,
    pageBuilder: (context, state) =>
        _page(state, wrapRoute(context, const FoldersScreen())),
    routes: [_searchRoute, _detailRoute],
  );

  static GoRoute get _searchRoute => GoRoute(
    name: AppRouteNames.folders.search,
    path: 'search',
    parentNavigatorKey: AppRouter.rootNavigatorKey,
    pageBuilder: (context, state) =>
        _page(state, wrapRoute(context, const FolderSearchScreen())),
  );

  static GoRoute get _detailRoute => GoRoute(
    name: AppRouteNames.folders.detail,
    path: ':id',
    pageBuilder: (context, state) => _page(
      state,
      wrapRoute(
        context,
        FolderDetailScreen(folderId: state.pathParameters['id']!),
      ),
    ),
    routes: [_noteDetailRoute],
  );

  static GoRoute get _noteDetailRoute => GoRoute(
    name: AppRouteNames.folders.noteDetail,
    path: 'note/:noteId',
    pageBuilder: (context, state) => _page(
      state,
      wrapRoute(
        context,
        NoteDetailScreen(
          folderId: state.pathParameters['id']!,
          noteId: state.pathParameters['noteId']!,
        ),
      ),
    ),
  );

  static Page<void> _page(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      restorationId: AppRestorationIds.page(_pagePath(state)),
      child: child,
    );
  }

  static String _pagePath(GoRouterState state) {
    return state.uri.path.replaceAll('/', '_');
  }
}
