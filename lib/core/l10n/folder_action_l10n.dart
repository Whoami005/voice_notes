import 'package:voice_notes/feature/presentation/pages/folders/widgets/folder_actions_sheet.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

extension FolderActionL10n on FolderAction {
  String title(AppLocalizations l10n) => switch (this) {
    FolderAction.edit => l10n.folderActionEdit,
    FolderAction.delete => l10n.folderActionDelete,
  };
}
