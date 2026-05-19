abstract final class AppRouteNames {
  static const folders = _FoldersRouteNames();
  static const settings = _SettingsRouteNames();
}

final class _FoldersRouteNames {
  const _FoldersRouteNames();

  String get root => 'folders-root';

  String get search => 'folders-search';

  String get detail => 'folders-detail';

  String get noteDetail => 'folders-note-detail';
}

final class _SettingsRouteNames {
  const _SettingsRouteNames();

  String get general => 'settings-general';

  String get models => 'settings-models';

  String get queue => 'settings-queue';

  String get storage => 'settings-storage';

  String get storageDetail => 'settings-storage-detail';
}
