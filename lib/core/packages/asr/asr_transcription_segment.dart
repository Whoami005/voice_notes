import 'package:equatable/equatable.dart';

class AsrTranscriptionSegment extends Equatable {
  final String text;
  final Duration start;
  final Duration end;
  final List<String> tokens;
  final List<double> timestamps;
  final String? detectedLanguage;

  const AsrTranscriptionSegment({
    required this.text,
    required this.start,
    required this.end,
    this.tokens = const [],
    this.timestamps = const [],
    this.detectedLanguage,
  });

  Duration get duration => end - start;

  AsrTranscriptionSegment copyWith({
    String? text,
    Duration? start,
    Duration? end,
    List<String>? tokens,
    List<double>? timestamps,
    String? detectedLanguage,
  }) {
    return AsrTranscriptionSegment(
      text: text ?? this.text,
      start: start ?? this.start,
      end: end ?? this.end,
      tokens: tokens ?? this.tokens,
      timestamps: timestamps ?? this.timestamps,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    );
  }

  @override
  List<Object?> get props => [
    text,
    start,
    end,
    tokens,
    timestamps,
    detectedLanguage,
  ];
}
