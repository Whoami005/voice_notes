import 'dart:async';

import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/path/audio_paths.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';
import 'package:voice_notes/core/state/status/status_cubit.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';

part 'note_playback_state.dart';

/// Cubit управления воспроизведением на экране детальной заметки.
///
/// Делегирует к shared [AudioPlaybackController].
class NotePlaybackCubit extends StatusCubit<NotePlaybackState> {
  final AudioPlaybackController _controller;
  final String _folderId;
  final String _noteId;

  StreamSubscription<TrackState>? _trackSub;
  List<double>? _waveformData;

  NotePlaybackCubit({
    required AudioPlaybackController controller,
    required String folderId,
    required String noteId,
  }) : _controller = controller,
       _folderId = folderId,
       _noteId = noteId,
       super(const NotePlaybackState());

  /// Нормализованные амплитуды для визуализации waveform.
  List<double>? get waveformData => _waveformData;

  /// Доступные скорости воспроизведения.
  static const List<double> availableSpeeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  Future<void> loadNote(NoteEntity note) async {
    final audio = note.origin.audio;
    if (audio == null) return;

    emitLoading();
    try {
      final absolutePath = await AudioPaths.resolveRelativePath(
        audio.relativePath,
      );

      _controller.register(
        _noteId,
        CachedTrackState(
          absolutePath: absolutePath,
          title: note.titleOrDisplayId,
          folderId: note.folderId ?? _folderId,
          duration: audio.duration,
        ),
      );

      await _trackSub?.cancel();
      _trackSub = _controller
          .trackStateStream(_noteId)
          .listen(_onTrackStateChanged);

      emitSuccess(
        state.copyWith(
          duration: audio.duration,
          speed: _controller.session.speed,
        ),
      );

      // Load waveform in background
      unawaited(
        _controller.getWaveform(_noteId).then((data) {
          if (data != null && !isClosed) {
            _waveformData = data;
            // Re-emit to trigger rebuild
            emitSuccess(state.copyWith());
          }
        }),
      );
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  Future<void> play() async {
    try {
      await _controller.play(_noteId);
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  Future<void> pause() async {
    try {
      await _controller.pause();
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  Future<void> togglePlayPause() =>
      state.playbackStatus.isPlaying ? pause() : play();

  Future<void> seek(Duration position) async {
    try {
      emitSuccess(state.copyWith(position: position));
      await _controller.seek(_noteId, position);
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _controller.setSpeed(speed);
      emitSuccess(state.copyWith(speed: speed));
    } catch (e, s) {
      emitError(logError(e, s));
    }
  }

  void _onTrackStateChanged(TrackState trackState) {
    emitSuccess(
      state.copyWith(
        playbackStatus: trackState.status,
        position: trackState.position,
        duration: trackState.duration,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _trackSub?.cancel();
    return super.close();
  }
}
