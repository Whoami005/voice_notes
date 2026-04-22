import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart'
    as jap;
import 'package:voice_notes/core/packages/player/audio_player_service.dart';

class JustAudioPlayerService implements AudioPlayerService {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  final StreamController<PlaybackStatus> _statusController =
      StreamController<PlaybackStatus>.broadcast();

  late final StreamSubscription<ja.PlayerState> _playerStateSub;
  late final StreamSubscription<ja.PlayerException> _playerErrorSub;

  PlaybackStatus _status = PlaybackStatus.init;

  JustAudioPlayerService() {
    unawaited(disposeLingeringJustAudioPlayers());
    _playerStateSub = _player.playerStateStream.listen(_onPlayerStateChanged);
    _playerErrorSub = _player.errorStream.listen(_onPlayerError);
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
  Future<Duration?> load(
    String absolutePath, {
    Duration initialPosition = Duration.zero,
  }) async {
    _emitStatus(PlaybackStatus.loading);

    try {
      return await _player.setFilePath(
        absolutePath,
        initialPosition: initialPosition,
      );
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
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _playerStateSub.cancel();
    await _playerErrorSub.cancel();
    await _statusController.close();
    await _player.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Private
  // ─────────────────────────────────────────────────────────────

  void _onPlayerStateChanged(ja.PlayerState playerState) =>
      _emitStatus(mapJustAudioPlayerState(playerState));

  void _onPlayerError(ja.PlayerException error) =>
      _emitStatus(PlaybackStatus.error);

  void _emitStatus(PlaybackStatus status) {
    if (_status == status) return;

    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}

@visibleForTesting
Future<void> disposeLingeringJustAudioPlayers() async {
  try {
    // Одного AudioPlayer() недостаточно: just_audio активирует platform layer
    // только позже, а lingering native players после hot restart нужно погасить
    // сразу при создании shared playback service.
    await jap.JustAudioPlatform.instance.disposeAllPlayers(
      jap.DisposeAllPlayersRequest(),
    );
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint(
        'disposeLingeringJustAudioPlayers failed: $error\n$stackTrace',
      );
    }
  }
}

@visibleForTesting
PlaybackStatus mapJustAudioPlayerState(ja.PlayerState playerState) {
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
