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

  StreamSubscription<String?>? _activeTrackSub;
  StreamSubscription<List<NoteEntity>>? _notesSub;
  final Map<String, StreamSubscription<TrackState>> _trackSubs = {};

  FolderPlaybackCubit({
    required AudioPlaybackController controller,
    required NoteRepository noteRepository,
    required String folderId,
  }) : _controller = controller,
       super(const FolderPlaybackState()) {
    _activeTrackSub = _controller.activeTrackIdStream.listen(
      _onActiveTrackChanged,
    );

    //TODO(K): Подумать как убрать или стоит ли вообще убирать,
    // так как FolderDetailCubit делает тоже самое
    _notesSub = noteRepository
        .watchByFolderId(folderId)
        .listen(_onNotesReceived);
  }

  Future<void> _onNotesReceived(List<NoteEntity> notes) async {
    for (final note in notes) {
      final audio = note.audio;
      if (audio == null || _trackSubs.containsKey(note.uuid)) continue;

      try {
        final absolutePath = await AudioPaths.resolveRelativePath(
          audio.relativePath,
        );

        _controller.register(
          note.uuid,
          CachedTrackState(
            absolutePath: absolutePath,
            duration: audio.duration,
          ),
        );
        _subscribeToTrack(note.uuid);
      } catch (_) {
        continue;
      }
    }

    unawaited(_loadWaveforms(notes).catchError((_) {}));
  }

  Future<void> _loadWaveforms(List<NoteEntity> notes) async {
    final additions = <String, List<double>>{};

    for (final note in notes) {
      if (note.audio == null) continue;
      if (state.waveforms.containsKey(note.uuid)) continue;

      final waveform = await _controller.getWaveform(note.uuid);
      if (waveform != null) additions[note.uuid] = waveform;
    }

    if (additions.isNotEmpty && !isClosed) {
      emit(state.copyWith(waveforms: {...state.waveforms, ...additions}));
    }
  }

  Future<void> togglePlayPause(String trackId) =>
      _controller.togglePlayPause(trackId);

  Future<void> seek(String trackId, Duration position) =>
      _controller.seek(trackId, position);

  void _onActiveTrackChanged(String? trackId) {
    emit(state.copyWith(activeTrackId: trackId));
  }

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

  @override
  Future<void> close() async {
    await _activeTrackSub?.cancel();
    await _notesSub?.cancel();
    for (final sub in _trackSubs.values) await sub.cancel();

    _trackSubs.clear();
    await _controller.releaseAll();

    return super.close();
  }
}
