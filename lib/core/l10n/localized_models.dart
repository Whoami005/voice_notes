import 'package:voice_notes/l10n/app_localizations.dart';

class LocalizedModels {
  const LocalizedModels._();

  static String? description(String uuid, AppLocalizations l10n) {
    return _descriptions(l10n)[uuid];
  }

  static String? languageLabel(String uuid, AppLocalizations l10n) {
    return _languageLabels(l10n)[uuid];
  }

  static Map<String, String> _descriptions(AppLocalizations l10n) => {
    'whisper-tiny-en': l10n.modelDescWhisperTiny,
    'whisper-small': l10n.modelDescWhisperSmall,
    'whisper-medium': l10n.modelDescWhisperMedium,
  };

  static Map<String, String> _languageLabels(AppLocalizations l10n) => {
    'whisper-tiny-en': l10n.modelLangEnglish,
    'whisper-small': l10n.modelLang99Languages,
    'whisper-medium': l10n.modelLang99Languages,
  };
}
