import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_plan.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';

final class QueuedTranscriptionTask {
  final String noteUid;
  final NoteAudioEntity audio;
  final AsrModelEntity model;
  final AsrTranscriptionPlan transcriptionPlan;
  final AsrCancelToken cancelToken;

  const QueuedTranscriptionTask({
    required this.noteUid,
    required this.audio,
    required this.model,
    required this.transcriptionPlan,
    required this.cancelToken,
  });
}
