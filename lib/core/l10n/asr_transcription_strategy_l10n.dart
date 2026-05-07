import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

extension AsrTranscriptionStrategyL10n on AsrTranscriptionStrategy {
  String title(AppLocalizations l10n) => switch (this) {
    AsrTranscriptionStrategy.auto => l10n.noteInfoStrategyAuto,
    AsrTranscriptionStrategy.streaming => l10n.noteInfoStrategyStreaming,
    AsrTranscriptionStrategy.singlePass => l10n.noteInfoStrategySinglePass,
    AsrTranscriptionStrategy.chunked => l10n.noteInfoStrategyChunked,
    AsrTranscriptionStrategy.chunkedVad => l10n.noteInfoStrategyChunkedVad,
  };
}
