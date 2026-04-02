import 'package:voice_notes/feature/domain/enums/recording_state.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

extension SearchFilterL10n on SearchFilter {
  String title(AppLocalizations l10n) => switch (this) {
    SearchFilter.all => l10n.searchFilterAll,
    SearchFilter.text => l10n.searchFilterText,
    SearchFilter.tags => l10n.searchFilterTags,
    SearchFilter.date => l10n.searchFilterDate,
  };
}
