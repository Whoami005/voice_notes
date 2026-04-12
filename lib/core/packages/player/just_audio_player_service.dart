import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:voice_notes/core/packages/player/audio_player_service.dart';

@Injectable(as: AudioPlayerService)
class JustAudioPlayerService implements AudioPlayerService {
  final ja.AudioPlayer _player;

  late final StreamController<PlaybackStatus> _statusController;
  late final StreamSubscription<ja.PlayerState> _playerStateSub;

  PlaybackStatus _status = PlaybackStatus.init;

  JustAudioPlayerService() : _player = ja.AudioPlayer() {
    _statusController = StreamController<PlaybackStatus>.broadcast();
    _playerStateSub = _player.playerStateStream.listen(_onPlayerStateChanged);
  }

  // ─────────────────────────────────────────────────────────────
  // Streams
  // ─────────────────────────────────────────────────────────────

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  // ─────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────

  @override
  PlaybackStatus get status => _status;

  @override
  Duration get position => _player.position;

  @override
  Duration? get duration => _player.duration;

  @override
  double get speed => _player.speed;

  // ─────────────────────────────────────────────────────────────
  // Controls
  // ─────────────────────────────────────────────────────────────

  @override
  Future<void> load(String absolutePath) async {
    _emitStatus(PlaybackStatus.loading);
    try {
      await _player.setFilePath(absolutePath);
      _emitStatus(PlaybackStatus.ready);
    } catch (e) {
      _emitStatus(PlaybackStatus.error);
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    if (_player.processingState == ja.ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }

    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await _player.stop();
    _emitStatus(PlaybackStatus.init);
  }

  @override
  Future<void> dispose() async {
    await _playerStateSub.cancel();
    await _statusController.close();
    await _player.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Private
  // ─────────────────────────────────────────────────────────────

  void _onPlayerStateChanged(ja.PlayerState playerState) =>
      _emitStatus(_mapPlayerState(playerState));

  PlaybackStatus _mapPlayerState(ja.PlayerState playerState) {
    // Порядок проверок важен: completed должен иметь приоритет над playing,
    // потому что just_audio держит playing==true даже после завершения.
    return switch (playerState.processingState) {
      ja.ProcessingState.idle => PlaybackStatus.init,
      ja.ProcessingState.loading ||
      ja.ProcessingState.buffering => PlaybackStatus.loading,
      ja.ProcessingState.ready =>
        playerState.playing ? PlaybackStatus.playing : PlaybackStatus.paused,
      ja.ProcessingState.completed => PlaybackStatus.completed,
    };
  }

  void _emitStatus(PlaybackStatus status) {
    if (_status == status) return;

    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}
