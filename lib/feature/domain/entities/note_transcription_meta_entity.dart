import 'package:equatable/equatable.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_task_type.dart';

class NoteTranscriptionMetaEntity extends Equatable {
  final AsrModelIdEnum modelId;
  final String? languageCode;
  final TranscriptionTaskType taskType;
  final DateTime transcribedAt;
  final Duration processingTime;
  final AsrTranscriptionStrategy strategyUsed;
  final bool usedVad;
  final bool fellBackFromVad;
  final String? emotionLabel;
  final String? eventLabel;
  final bool? usedItn;
  final bool? usedPunctuation;

  String? get detectedLanguageCode => languageCode;

  const NoteTranscriptionMetaEntity({
    required this.modelId,
    required this.taskType,
    required this.transcribedAt,
    required this.processingTime,
    required this.strategyUsed,
    required this.usedVad,
    required this.fellBackFromVad,
    this.languageCode,
    this.emotionLabel,
    this.eventLabel,
    this.usedItn,
    this.usedPunctuation,
  });

  NoteTranscriptionMetaEntity copyWith({
    AsrModelIdEnum? modelId,
    String? Function()? languageCode,
    TranscriptionTaskType? taskType,
    DateTime? transcribedAt,
    Duration? processingTime,
    AsrTranscriptionStrategy? strategyUsed,
    bool? usedVad,
    bool? fellBackFromVad,
    String? Function()? emotionLabel,
    String? Function()? eventLabel,
    bool? Function()? usedItn,
    bool? Function()? usedPunctuation,
  }) {
    return NoteTranscriptionMetaEntity(
      modelId: modelId ?? this.modelId,
      languageCode: languageCode != null ? languageCode() : this.languageCode,
      taskType: taskType ?? this.taskType,
      transcribedAt: transcribedAt ?? this.transcribedAt,
      processingTime: processingTime ?? this.processingTime,
      strategyUsed: strategyUsed ?? this.strategyUsed,
      usedVad: usedVad ?? this.usedVad,
      fellBackFromVad: fellBackFromVad ?? this.fellBackFromVad,
      emotionLabel: emotionLabel != null ? emotionLabel() : this.emotionLabel,
      eventLabel: eventLabel != null ? eventLabel() : this.eventLabel,
      usedItn: usedItn != null ? usedItn() : this.usedItn,
      usedPunctuation: usedPunctuation != null
          ? usedPunctuation()
          : this.usedPunctuation,
    );
  }

  @override
  List<Object?> get props => [
    modelId,
    languageCode,
    taskType,
    transcribedAt,
    processingTime,
    strategyUsed,
    usedVad,
    fellBackFromVad,
    emotionLabel,
    eventLabel,
    usedItn,
    usedPunctuation,
  ];
}
