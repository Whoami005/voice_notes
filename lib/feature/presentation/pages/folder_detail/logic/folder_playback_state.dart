part of 'folder_playback_cubit.dart';

class FolderPlaybackState extends Equatable {
  final Map<String, TrackState> trackStates;
  final Map<String, List<double>> waveforms;

  const FolderPlaybackState({
    this.trackStates = const {},
    this.waveforms = const {},
  });

  TrackState trackState(String trackId) =>
      trackStates[trackId] ?? const TrackState.initial();

  List<double>? waveform(String trackId) => waveforms[trackId];

  bool isPlaying(String trackId) => trackState(trackId).status.isPlaying;

  FolderPlaybackState copyWith({
    Map<String, TrackState>? trackStates,
    Map<String, List<double>>? waveforms,
  }) {
    return FolderPlaybackState(
      trackStates: trackStates ?? this.trackStates,
      waveforms: waveforms ?? this.waveforms,
    );
  }

  @override
  List<Object?> get props => [trackStates, waveforms];
}
