import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

part 'folder_playback_state.dart';

/// Управление воспроизведением аудио на экране списка заметок.
class FolderPlaybackCubit extends Cubit<FolderPlaybackState> {
  final AudioPlaybackController _controller;
  final String _folderId;

  StreamSubscription<List<NoteEntity>>? _notesSub;
  final Map<String, StreamSubscription<TrackState>> _trackSubs = {};
  final Set<String> _loadingWaveformIds = {};

  FolderPlaybackCubit({
    required AudioPlaybackController controller,
    required NoteRepository noteRepository,
    required String folderId,
  }) : _controller = controller,
       _folderId = folderId,
       super(const FolderPlaybackState()) {
    //TODO(K): Подумать как убрать или стоит ли вообще убирать,
    // так как FolderDetailCubit делает тоже самое
    _notesSub = noteRepository
        .watchByFolderId(folderId)
        .listen(_onNotesReceived);
  }

  Future<void> _onNotesReceived(List<NoteEntity> notes) async {
    for (final note in notes) await _ensureTrackRegistered(note);
  }

  Future<void> ensureWaveformLoaded(NoteEntity note) async {
    if (note.audio == null) return;
    if (state.waveforms.containsKey(note.uuid)) return;
    if (_loadingWaveformIds.contains(note.uuid)) return;

    _loadingWaveformIds.add(note.uuid);

    try {
      await _ensureTrackRegistered(note);
      final waveform = await _controller.getWaveform(note.uuid);

      if (waveform == null || isClosed) return;
      if (state.waveforms.containsKey(note.uuid)) return;

      emit(
        state.copyWith(waveforms: {...state.waveforms, note.uuid: waveform}),
      );
    } catch (_) {
      return;
    } finally {
      _loadingWaveformIds.remove(note.uuid);
    }
  }

  Future<void> togglePlayPause(String trackId) =>
      _controller.togglePlayPause(trackId);

  Future<void> seek(String trackId, Duration position) =>
      _controller.seek(trackId, position);

  void _subscribeToTrack(String trackId) {
    if (_trackSubs.containsKey(trackId)) return;

    _trackSubs[trackId] = _controller.trackStateStream(trackId).listen((
      trackState,
    ) {
      if (isClosed) return;

      emit(
        state.copyWith(
          trackStates: {...state.trackStates, trackId: trackState},
        ),
      );
    });
  }

  Future<void> _ensureTrackRegistered(NoteEntity note) async {
    final audio = note.audio;
    if (audio == null) return;

    try {
      final absolutePath = await AudioPaths.resolveRelativePath(
        audio.relativePath,
      );

      _controller.register(
        note.uuid,
        CachedTrackState(
          absolutePath: absolutePath,
          title: note.text.trim(),
          folderId: note.folderId ?? _folderId,
          duration: audio.duration,
        ),
      );
      if (!_trackSubs.containsKey(note.uuid)) _subscribeToTrack(note.uuid);
    } catch (_) {
      return;
    }
  }

  @override
  Future<void> close() async {
    await _notesSub?.cancel();
    for (final sub in _trackSubs.values) await sub.cancel();

    _trackSubs.clear();
    return super.close();
  }
}
