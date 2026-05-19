abstract final class AppRestorationIds {
  static const app = 'voice_notes_app';
  static const router = 'voice_notes_router';
  static const rootShell = 'root_shell';
  static const foldersBranch = 'folders_branch';
  static const settingsBranch = 'settings_branch';
  static const foldersPaneShell = 'folders_pane_shell';
  static const settingsShell = 'settings_shell';

  static String page(String name) => 'page_$name';
}
