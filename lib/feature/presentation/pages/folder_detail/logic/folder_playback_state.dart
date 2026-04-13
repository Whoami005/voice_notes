part of 'folder_playback_cubit.dart';

const _sentinel = Object();

class FolderPlaybackState extends Equatable {
  final String? activeTrackId;
  final Map<String, TrackState> trackStates;
  final Map<String, List<double>> waveforms;

  const FolderPlaybackState({
    this.activeTrackId,
    this.trackStates = const {},
    this.waveforms = const {},
  });

  TrackState trackState(String trackId) =>
      trackStates[trackId] ?? const TrackState.initial();

  List<double>? waveform(String trackId) => waveforms[trackId];

  bool isPlaying(String trackId) => activeTrackId == trackId;

  FolderPlaybackState copyWith({
    Object? activeTrackId = _sentinel,
    Map<String, TrackState>? trackStates,
    Map<String, List<double>>? waveforms,
  }) {
    return FolderPlaybackState(
      activeTrackId: activeTrackId == _sentinel
          ? this.activeTrackId
          : activeTrackId as String?,
      trackStates: trackStates ?? this.trackStates,
      waveforms: waveforms ?? this.waveforms,
    );
  }

  @override
  List<Object?> get props => [activeTrackId, trackStates, waveforms];
}
