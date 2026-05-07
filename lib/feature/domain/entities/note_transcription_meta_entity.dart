import 'package:equatable/equatable.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

class NoteTranscriptionMetaEntity extends Equatable {
  final AsrModelIdEnum modelId;
  final String? detectedLanguageCode;
  final DateTime transcribedAt;

  const NoteTranscriptionMetaEntity({
    required this.modelId,
    required this.transcribedAt,
    this.detectedLanguageCode,
  });

  NoteTranscriptionMetaEntity copyWith({
    AsrModelIdEnum? modelId,
    String? Function()? detectedLanguageCode,
    DateTime? transcribedAt,
  }) {
    return NoteTranscriptionMetaEntity(
      modelId: modelId ?? this.modelId,
      detectedLanguageCode: detectedLanguageCode != null
          ? detectedLanguageCode()
          : this.detectedLanguageCode,
      transcribedAt: transcribedAt ?? this.transcribedAt,
    );
  }

  @override
  List<Object?> get props => [modelId, detectedLanguageCode, transcribedAt];
}
