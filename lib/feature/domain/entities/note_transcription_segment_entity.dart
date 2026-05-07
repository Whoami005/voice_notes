import 'package:equatable/equatable.dart';

class NoteTranscriptionSegmentEntity extends Equatable {
  final int index;
  final String text;
  final Duration start;
  final Duration end;
  final String? languageCode;
  final List<String>? tokens;
  final List<Duration>? tokenTimestamps;

  const NoteTranscriptionSegmentEntity({
    required this.index,
    required this.text,
    required this.start,
    required this.end,
    this.languageCode,
    this.tokens,
    this.tokenTimestamps,
  });

  Duration get duration => end - start;

  NoteTranscriptionSegmentEntity copyWith({
    int? index,
    String? text,
    Duration? start,
    Duration? end,
    String? Function()? languageCode,
    List<String>? Function()? tokens,
    List<Duration>? Function()? tokenTimestamps,
  }) {
    return NoteTranscriptionSegmentEntity(
      index: index ?? this.index,
      text: text ?? this.text,
      start: start ?? this.start,
      end: end ?? this.end,
      languageCode: languageCode != null ? languageCode() : this.languageCode,
      tokens: tokens != null ? tokens() : this.tokens,
      tokenTimestamps: tokenTimestamps != null
          ? tokenTimestamps()
          : this.tokenTimestamps,
    );
  }

  @override
  List<Object?> get props => [
    index,
    text,
    start,
    end,
    languageCode,
    tokens,
    tokenTimestamps,
  ];
}
