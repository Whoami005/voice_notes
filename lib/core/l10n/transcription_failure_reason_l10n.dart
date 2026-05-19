import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

extension TranscriptionFailureReasonL10n on TranscriptionFailureReason {
  String title(AppLocalizations l10n) => switch (this) {
    TranscriptionFailureReason.noModelSelected => l10n.noteFailureNoModel,
    TranscriptionFailureReason.modelLoadFailed => l10n.noteFailureModelLoad,
    TranscriptionFailureReason.transcriptionFailed =>
      l10n.noteFailureTranscription,
    TranscriptionFailureReason.audioFileMissing => l10n.noteFailureAudioMissing,
    TranscriptionFailureReason.audioFileCorrupted =>
      l10n.noteFailureAudioCorrupted,
    TranscriptionFailureReason.transcriptionTimedOut =>
      l10n.noteFailureTimedOut,
    TranscriptionFailureReason.unknown => l10n.noteFailureUnknown,
  };
}
