import 'package:voice_notes/l10n/app_localizations.dart';

enum NoteTranscriptionHelpTopic {
  recognitionMode,
  speechDetection,
  fallbackMode,
  textNormalization,
  autoPunctuation,
}

extension NoteTranscriptionHelpTopicL10n on NoteTranscriptionHelpTopic {
  String title(AppLocalizations l10n) => switch (this) {
    NoteTranscriptionHelpTopic.recognitionMode =>
      l10n.noteInfoStrategySheetTitle,
    NoteTranscriptionHelpTopic.speechDetection =>
      l10n.noteInfoSpeechDetectionSheetTitle,
    NoteTranscriptionHelpTopic.fallbackMode =>
      l10n.noteInfoFallbackModeSheetTitle,
    NoteTranscriptionHelpTopic.textNormalization =>
      l10n.noteInfoTextNormalizationSheetTitle,
    NoteTranscriptionHelpTopic.autoPunctuation =>
      l10n.noteInfoAutoPunctuationSheetTitle,
  };

  String description(AppLocalizations l10n) => switch (this) {
    NoteTranscriptionHelpTopic.recognitionMode =>
      l10n.noteInfoStrategySheetDescription,
    NoteTranscriptionHelpTopic.speechDetection =>
      l10n.noteInfoSpeechDetectionSheetDescription,
    NoteTranscriptionHelpTopic.fallbackMode =>
      l10n.noteInfoFallbackModeSheetDescription,
    NoteTranscriptionHelpTopic.textNormalization =>
      l10n.noteInfoTextNormalizationSheetDescription,
    NoteTranscriptionHelpTopic.autoPunctuation =>
      l10n.noteInfoAutoPunctuationSheetDescription,
  };

  String note(AppLocalizations l10n) => switch (this) {
    NoteTranscriptionHelpTopic.recognitionMode =>
      l10n.noteInfoStrategySheetNote,
    NoteTranscriptionHelpTopic.speechDetection =>
      l10n.noteInfoSpeechDetectionSheetNote,
    NoteTranscriptionHelpTopic.fallbackMode =>
      l10n.noteInfoFallbackModeSheetNote,
    NoteTranscriptionHelpTopic.textNormalization =>
      l10n.noteInfoTextNormalizationSheetNote,
    NoteTranscriptionHelpTopic.autoPunctuation =>
      l10n.noteInfoAutoPunctuationSheetNote,
  };
}
