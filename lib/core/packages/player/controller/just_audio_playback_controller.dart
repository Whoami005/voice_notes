import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';
import 'package:voice_notes/core/packages/player/controller/just_audio_playback_waveform.dart';
import 'package:voice_notes/core/packages/player/just_audio_player_service.dart';

@Singleton(as: AudioPlaybackController)
class JustAudioPlaybackController implements AudioPlaybackController {
  final AudioPlayerService _player;
  final WaveformLoader _waveformLoader;

  final Map<String, CachedTrackState> _cache = {};
  final Map<String, List<double>> _waveformCache = {};
  final Map<String, _WaveformRequest> _waveformRequests = {};
  final Map<String, int> _waveformRevisions = {};
  final Map<String, BehaviorSubject<TrackState>> _subjects = {};

  String? _activeTrackId;
  PlaybackSessionState _session = const PlaybackSessionState.hidden();
  final BehaviorSubject<PlaybackSessionState> _sessionSubject =
      BehaviorSubject.seeded(const PlaybackSessionState.hidden());

  double _speed = 1;

  StreamSubscription<PlaybackStatus>? _statusSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  JustAudioPlaybackController()
    : _player = JustAudioPlayerService(),
      _waveformLoader = extractWaveformFromPath;

  @visibleForTesting
  JustAudioPlaybackController.withPlayer(
    AudioPlayerService player, {
    WaveformLoader? waveformLoader,
  }) : _player = player,
       _waveformLoader = waveformLoader ?? extractWaveformFromPath;

  @override
  void register(String trackId, CachedTrackState state) {
    final cached = _cache[trackId];
    if (cached == null) {
      _cache[trackId] = state;
      _waveformRevisions.putIfAbsent(trackId, () => 0);
      _refreshSession(trackId);
      return;
    }

    final pathChanged = cached.absolutePath != state.absolutePath;
    final nextDuration = state.duration > Duration.zero
        ? state.duration
        : cached.duration;
    cached
      ..absolutePath = state.absolutePath
      ..title = state.title
      ..folderId = state.folderId
      ..duration = nextDuration;

    if (pathChanged) _invalidateWaveform(trackId);
    _emitTrackState(trackId, _buildTrackState(cached));
  }

  @override
  Future<void> play(String trackId) async {
    final cached = _cache[trackId];
    if (cached == null) return;

    if (_activeTrackId == trackId) {
      if (_player.status.isCompleted) {
        await _player.seek(Duration.zero);
        _syncActiveTrackState();
      }

      await _player.play();
      return;
    }

    await _persistActiveTrack();
    _activeTrackId = trackId;
    _subscribeToPlayer(trackId);
    _emitTrackState(
      trackId,
      TrackState(
        status: PlaybackStatus.loading,
        position: _resumePositionFor(cached),
        duration: cached.duration,
      ),
    );

    await _player.load(
      cached.absolutePath,
      initialPosition: _resumePositionFor(cached),
    );
    await _player.setSpeed(_speed);
    _syncActiveTrackState();
    await _player.play();
  }

  @override
  Future<void> pause() async {
    final trackId = _activeTrackId;
    if (trackId == null) return;

    await _player.pause();
    final cached = _cache[trackId];
    if (cached == null) {
      _hideSession();
      return;
    }

    _emitTrackState(
      trackId,
      TrackState(
        status: PlaybackStatus.paused,
        position: _player.position,
        duration: _player.duration ?? cached.duration,
      ),
    );
  }

  @override
  Future<void> togglePlayPause(String trackId) async {
    final isPlaying = _activeTrackId == trackId && _player.status.isPlaying;
    if (isPlaying) {
      await pause();
      return;
    }

    await play(trackId);
  }

  @override
  Future<void> seek(String trackId, Duration position) async {
    if (_activeTrackId == trackId) {
      await _player.seek(position);
      return;
    }

    final cached = _cache[trackId];
    if (cached == null) return;

    _emitTrackState(
      trackId,
      TrackState(
        status: cached.status,
        position: position,
        duration: cached.duration,
      ),
    );
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _player.setSpeed(speed);

    if (_session.isVisible) {
      _refreshSession(_session.trackId);
      return;
    }

    _hideSession();
  }

  @override
  Stream<TrackState> trackStateStream(String trackId) {
    return _getOrCreateSubject(trackId).stream;
  }

  @override
  PlaybackSessionState get session => _session;

  @override
  Stream<PlaybackSessionState> get sessionStream => _sessionSubject.stream;

  @override
  Future<void> clearSession() async {
    if (_activeTrackId != null) {
      await _persistActiveTrack();
      await _player.stop();
      _activeTrackId = null;
    }

    _hideSession();
  }

  @override
  Future<List<double>?> getWaveform(String trackId) async {
    final cached = _waveformCache[trackId];
    if (cached != null) return cached;

    final revision = _waveformRevision(trackId);
    final inFlight = _waveformRequests[trackId];
    if (inFlight != null && inFlight.revision == revision) {
      return inFlight.future;
    }

    final request = _loadWaveform(trackId, revision);
    _waveformRequests[trackId] = _WaveformRequest(
      future: request,
      revision: revision,
    );

    return request;
  }

  @override
  @disposeMethod
  Future<void> dispose() async {
    await clearSession();
    _cache.clear();
    _waveformCache.clear();
    _waveformRequests.clear();
    _waveformRevisions.clear();

    for (final subject in _subjects.values) {
      await subject.close();
    }
    _subjects.clear();

    await _sessionSubject.close();
    await _player.dispose();
  }

  BehaviorSubject<TrackState> _getOrCreateSubject(String trackId) {
    final existing = _subjects[trackId];
    if (existing != null && !existing.isClosed) return existing;

    final cached = _cache[trackId];
    final seed = cached != null
        ? _buildTrackState(cached)
        : const TrackState.initial();

    final subject = BehaviorSubject.seeded(seed);
    _subjects[trackId] = subject;

    return subject;
  }

  void _emitTrackState(String trackId, TrackState state) {
    _updateCachedTrack(trackId, state);

    final subject = _subjects[trackId];
    if (subject != null && !subject.isClosed) subject.add(state);

    _refreshSession(trackId);
  }

  void _updateCachedTrack(String trackId, TrackState state) {
    final cached = _cache[trackId];
    if (cached == null) return;

    cached
      ..position = state.position
      ..duration = state.duration
      ..status = state.status;
  }

  TrackState _buildTrackState(CachedTrackState cached) {
    return TrackState(
      status: cached.status,
      position: cached.position,
      duration: cached.duration,
    );
  }

  Future<void> _persistActiveTrack() async {
    final currentId = _activeTrackId;
    if (currentId == null) return;

    await _cancelPlayerSubscriptions();

    final cached = _cache[currentId];
    if (cached == null) return;

    final previousStatus = _player.status;
    await _player.pause();

    _emitTrackState(
      currentId,
      TrackState(
        status: _deactivatedStatus(previousStatus),
        position: _player.position,
        duration: _player.duration ?? cached.duration,
      ),
    );
  }

  PlaybackStatus _deactivatedStatus(PlaybackStatus status) {
    return switch (status) {
      PlaybackStatus.completed => PlaybackStatus.completed,
      PlaybackStatus.error => PlaybackStatus.error,
      PlaybackStatus.init => PlaybackStatus.init,
      _ => PlaybackStatus.paused,
    };
  }

  Duration _resumePositionFor(CachedTrackState cached) {
    return cached.status.isCompleted ? Duration.zero : cached.position;
  }

  void _syncTrackStateIfActive(String trackId) {
    if (_activeTrackId != trackId) return;
    _syncActiveTrackState();
  }

  void _syncActiveTrackState() {
    final trackId = _activeTrackId;
    if (trackId == null) return;

    final cached = _cache[trackId];
    if (cached == null) return;

    final displayStatus = _displayTrackStatus(
      playerStatus: _player.status,
      previousStatus: cached.status,
    );

    _emitTrackState(
      trackId,
      TrackState(
        status: displayStatus,
        position: _player.position,
        duration: _player.duration ?? cached.duration,
      ),
    );
  }

  PlaybackStatus _displayTrackStatus({
    required PlaybackStatus playerStatus,
    required PlaybackStatus previousStatus,
  }) {
    if (playerStatus.isLoading && previousStatus.isPlaying) {
      return PlaybackStatus.playing;
    }

    return playerStatus;
  }

  Future<List<double>?> _loadWaveform(String trackId, int revision) async {
    final path = _cache[trackId]?.absolutePath;
    if (path == null) return null;

    try {
      final waveform = await _waveformLoader(trackId, path);
      if (_waveformRevision(trackId) != revision) return null;
      if (waveform != null) _waveformCache[trackId] = waveform;

      return waveform;
    } finally {
      final current = _waveformRequests[trackId];
      if (current?.revision == revision) _waveformRequests.remove(trackId);
    }
  }

  int _waveformRevision(String trackId) {
    return _waveformRevisions.putIfAbsent(trackId, () => 0);
  }

  void _invalidateWaveform(String trackId) {
    _waveformRevisions[trackId] = _waveformRevision(trackId) + 1;
    _waveformCache.remove(trackId);
  }

  void _refreshSession(String? trackId) {
    if (trackId == null || _activeTrackId != trackId) return;

    final cached = _cache[trackId];
    if (cached == null || !cached.status.isPlaying) {
      _hideSession();
      return;
    }

    _emitSession(
      PlaybackSessionState(
        trackId: trackId,
        title: cached.title,
        folderId: cached.folderId,
        status: cached.status,
        position: cached.position,
        duration: cached.duration,
        speed: _speed,
      ),
    );
  }

  void _hideSession() {
    _emitSession(PlaybackSessionState.hidden(speed: _speed));
  }

  void _emitSession(PlaybackSessionState session) {
    _session = session;
    if (!_sessionSubject.isClosed) _sessionSubject.add(session);
  }

  void _subscribeToPlayer(String trackId) {
    _statusSub = _player.statusStream.listen(
      (_) => _syncTrackStateIfActive(trackId),
    );
    _positionSub = _player.positionStream.listen(
      (_) => _syncTrackStateIfActive(trackId),
    );
    _durationSub = _player.durationStream.listen(
      (_) => _syncTrackStateIfActive(trackId),
    );
  }

  Future<void> _cancelPlayerSubscriptions() async {
    await _statusSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();

    _statusSub = null;
    _positionSub = null;
    _durationSub = null;
  }
}

class _WaveformRequest {
  final Future<List<double>?> future;
  final int revision;

  const _WaveformRequest({required this.future, required this.revision});
}
