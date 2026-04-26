import 'package:voice_notes/core/packages/asr/asr_transcription_plan.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_planner.dart';
import 'package:voice_notes/core/packages/asr/asr_vad_asset_installer.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';

final class TranscriptionTaskPlanner {
  TranscriptionTaskPlanner({AsrVadAssetInstaller? vadAssetInstaller})
    : _vadAssetInstaller = vadAssetInstaller ?? AsrVadAssetInstaller();

  final AsrVadAssetInstaller _vadAssetInstaller;

  Future<AsrTranscriptionPlan> buildPlan({
    required AsrModelEntity model,
    required NoteAudioEntity audio,
  }) async {
    final vadModelPath = await _vadAssetInstaller.resolveModelPath();

    return AsrTranscriptionPlanner.resolve(
      model: model,
      audioDuration: audio.duration,
      vadModelPath: vadModelPath,
    );
  }
}
