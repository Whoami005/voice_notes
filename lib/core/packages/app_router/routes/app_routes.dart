/// Иерархическая структура путей приложения.
///
/// Использование:
/// ```dart
/// // Навигация
/// context.go(AppRoutes.folders.root);
/// context.go(AppRoutes.folders.detail('123'));
/// context.go(AppRoutes.folders.noteDetail(folderId: '123', noteId: '456'));
/// context.go(AppRoutes.settings.root);
/// ```
abstract class AppRoutes {
  const AppRoutes._();

  static const folders = _FoldersRoutes();
  static const settings = _SettingsRoutes();
}

/// Пути для раздела Folders
class _FoldersRoutes {
  const _FoldersRoutes();

  /// Шаблон пути для GoRoute: /folders
  String get pattern => '/folders';

  /// Путь для навигации: /folders
  String get root => '/folders';

  /// Путь для навигации: /folders/:id
  String detail(String id) => '$pattern/$id';

  /// Путь для навигации: /folders/:id/note/:noteId
  String noteDetail({required String folderId, required String noteId}) =>
      '$pattern/$folderId/note/$noteId';
}

/// Пути для раздела Settings
class _SettingsRoutes {
  const _SettingsRoutes();

  /// Шаблон пути для GoRoute: /settings
  String get pattern => '/settings';

  /// Путь для навигации: /settings
  String get root => '/settings';
}
