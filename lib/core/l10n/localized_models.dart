import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class LocalizedModels {
  const LocalizedModels._();

  static String name(AsrModelIdEnum uuid) {
    for (final model in AsrModelEntity.availableModels) {
      if (model.uuid == uuid) return model.name;
    }

    return uuid.value;
  }

  static String? description(AsrModelIdEnum uuid, AppLocalizations l10n) {
    return _descriptions(l10n)[uuid];
  }

  static String? languageLabel(AsrModelIdEnum uuid, AppLocalizations l10n) {
    return _languageLabels(l10n)[uuid];
  }

  static Map<AsrModelIdEnum, String> _descriptions(AppLocalizations l10n) => {
    AsrModelIdEnum.whisperTinyEn: l10n.modelDescWhisperTiny,
    AsrModelIdEnum.whisperSmall: l10n.modelDescWhisperSmall,
    AsrModelIdEnum.whisperMedium: l10n.modelDescWhisperMedium,
    AsrModelIdEnum.parakeetTdtV3: l10n.modelDescParakeetV3,
    AsrModelIdEnum.streamingZipformerEn: l10n.modelDescZipformerEn,
    AsrModelIdEnum.streamingZipformerEn20M: l10n.modelDescZipformerEn20M,
  };

  static Map<AsrModelIdEnum, String> _languageLabels(AppLocalizations l10n) => {
    AsrModelIdEnum.whisperTinyEn: l10n.modelLangEnglish,
    AsrModelIdEnum.whisperSmall: l10n.modelLang99Languages,
    AsrModelIdEnum.whisperMedium: l10n.modelLang99Languages,
    AsrModelIdEnum.parakeetTdtV3: l10n.modelLang25Languages,
    AsrModelIdEnum.streamingZipformerEn: l10n.modelLangEnglish,
    AsrModelIdEnum.streamingZipformerEn20M: l10n.modelLangEnglish,
  };
}
