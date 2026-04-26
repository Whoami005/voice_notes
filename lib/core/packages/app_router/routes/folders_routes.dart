import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/app_router.dart';
import 'package:voice_notes/core/packages/app_router/route_builder.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/screens/folder_detail_screen.dart';
import 'package:voice_notes/feature/presentation/pages/folder_search/screens/folder_search_screen.dart';
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
  static StatefulShellBranch branch() =>
      StatefulShellBranch(routes: [_rootRoute]);

  static GoRoute get _rootRoute => GoRoute(
    path: AppRoutes.folders.pattern,
    builder: (context, state) => wrapRoute(context, const FoldersScreen()),
    routes: [_searchRoute, _detailRoute],
  );

  static GoRoute get _searchRoute => GoRoute(
    path: 'search',
    parentNavigatorKey: AppRouter.rootNavigatorKey,
    builder: (context, state) => wrapRoute(context, const FolderSearchScreen()),
  );

  static GoRoute get _detailRoute => GoRoute(
    path: ':id',
    parentNavigatorKey: AppRouter.rootNavigatorKey,
    builder: (context, state) => wrapRoute(
      context,
      FolderDetailScreen(folderId: state.pathParameters['id']!),
    ),
    routes: [_noteDetailRoute],
  );

  static GoRoute get _noteDetailRoute => GoRoute(
    path: 'note/:noteId',
    parentNavigatorKey: AppRouter.rootNavigatorKey,
    builder: (context, state) => wrapRoute(
      context,
      NoteDetailScreen(
        folderId: state.pathParameters['id']!,
        noteId: state.pathParameters['noteId']!,
      ),
    ),
  );
}
