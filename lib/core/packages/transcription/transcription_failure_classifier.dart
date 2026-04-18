import 'dart:io';

import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';

/// Метка таймаута ASR: отдельная семантика от обычных
/// [AsrProcessingException], чтобы [classifyTranscriptionFailure] мог
/// различить их. Public, т.к. сервис её `throw`'ит.
final class TranscribeTimeoutException extends AsrProcessingException {
  const TranscribeTimeoutException() : super('ASR transcription timed out');
}

/// Маппит ошибку процесса транскрибации в доменный
/// [TranscriptionFailureReason].
///
/// Порядок веток критичен: [TranscribeTimeoutException] должен проверяться
/// ДО [AsrProcessingException] (его родителя), иначе таймаут улетит в
/// `transcriptionFailed` вместо `transcriptionTimedOut`.
TranscriptionFailureReason classifyTranscriptionFailure(
  Object error,
) => switch (error) {
  TranscribeTimeoutException() =>
    TranscriptionFailureReason.transcriptionTimedOut,
  AsrNotInitializedException() => TranscriptionFailureReason.noModelSelected,
  AsrModelNotFoundException() => TranscriptionFailureReason.modelLoadFailed,
  AsrInvalidAudioException() => TranscriptionFailureReason.audioFileCorrupted,
  AsrProcessingException() => TranscriptionFailureReason.transcriptionFailed,
  FileSystemException() => TranscriptionFailureReason.audioFileMissing,
  _ => TranscriptionFailureReason.unknown,
};
