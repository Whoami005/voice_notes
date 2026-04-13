import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';
import 'package:voice_notes/core/packages/player/just_audio_player_service.dart';

@Singleton(as: AudioPlaybackController)
class JustAudioPlaybackController implements AudioPlaybackController {
  late final AudioPlayerService _player;

  /// trackId → cached state (created at registration time)
  final Map<String, CachedTrackState> _cache = {};

  /// trackId → normalized amplitudes (0.0–1.0) for waveform rendering
  final Map<String, List<double>> _waveformCache = {};

  /// trackId → BehaviorSubject for UI
  final Map<String, BehaviorSubject<TrackState>> _subjects = {};

  /// Currently active (loaded into player) track ID
  String? _activeTrackId;
  final BehaviorSubject<String?> _activeTrackSubject = BehaviorSubject.seeded(
    null,
  );

  double _speed = 1;

  StreamSubscription<PlaybackStatus>? _statusSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  JustAudioPlaybackController() {
    _player = JustAudioPlayerService();
  }

  @visibleForTesting
  JustAudioPlaybackController.withPlayer(AudioPlayerService player)
    : _player = player;

  // ─────────────────────────────────────────────────────────────
  // Registration
  // ─────────────────────────────────────────────────────────────

  @override
  void register(String trackId, CachedTrackState state) {
    _cache.putIfAbsent(trackId, () => state);
  }

  // ─────────────────────────────────────────────────────────────
  // Playback
  // ─────────────────────────────────────────────────────────────

  @override
  Future<void> play(String trackId) async {
    final path = _cache[trackId]?.absolutePath;
    if (path == null) return;

    if (_activeTrackId == trackId) {
      if (_player.status.isCompleted) await _player.seek(Duration.zero);
      await _player.play();

      return;
    }

    await _cacheActiveTrack();
    await _loadTrack(trackId, path);
    await _player.play();
  }

  @override
  Future<void> pause() async {
    if (_activeTrackId == null) return;
    await _player.pause();
  }

  @override
  Future<void> togglePlayPause(String trackId) async {
    final isPlaying = _activeTrackId == trackId && _player.status.isPlaying;

    isPlaying ? await pause() : await play(trackId);
  }

  @override
  Future<void> seek(String trackId, Duration position) async {
    if (_activeTrackId == trackId) {
      await _player.seek(position);
      return;
    }

    final cached = _cache[trackId];
    if (cached == null) return;

    cached.position = position;

    _emitToSubject(
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
  }

  // ─────────────────────────────────────────────────────────────
  // Streams
  // ─────────────────────────────────────────────────────────────

  @override
  Stream<TrackState> trackStateStream(String trackId) {
    return _getOrCreateSubject(trackId).stream;
  }

  @override
  Stream<String?> get activeTrackIdStream => _activeTrackSubject.stream;

  @override
  String? get activeTrackId => _activeTrackId;

  @override
  double get speed => _speed;

  // ─────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────

  @override
  Future<void> releaseAll() async {
    await _cancelPlayerSubscriptions();
    await _player.stop();

    _activeTrackId = null;
    _activeTrackSubject.add(null);
    _cache.clear();
    _waveformCache.clear();

    for (final subject in _subjects.values) await subject.close();
    _subjects.clear();
  }

  @override
  @disposeMethod
  Future<void> dispose() async {
    await releaseAll();
    await _activeTrackSubject.close();
    await _player.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Waveform
  // ─────────────────────────────────────────────────────────────

  @override
  Future<List<double>?> getWaveform(String trackId) async {
    final cached = _waveformCache[trackId];
    if (cached != null) return cached;

    final path = _cache[trackId]?.absolutePath;
    if (path == null) return null;

    try {
      final file = File(path);
      if (!file.existsSync()) return null;

      final tempDir = await getTemporaryDirectory();
      final waveOutFile = File(
        '${tempDir.path}/waveform_${trackId.hashCode}.wave',
      );

      final completer = Completer<Waveform?>();

      JustWaveform.extract(audioInFile: file, waveOutFile: waveOutFile).listen(
        (progress) {
          if (progress.waveform != null && !completer.isCompleted) {
            completer.complete(progress.waveform);
          }
        },
        onError: (e) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      final waveform = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (waveform == null || waveform.length == 0) return null;

      const sampleCount = 100;
      final step = waveform.length ~/ sampleCount;
      if (step == 0) return null;

      double maxAmp = 0;
      final raw = <double>[];

      for (var i = 0; i < waveform.length; i += step) {
        final pixelMax = waveform.getPixelMax(i).abs().toDouble();
        final pixelMin = waveform.getPixelMin(i).abs().toDouble();
        final amp = pixelMax > pixelMin ? pixelMax : pixelMin;

        raw.add(amp);
        if (amp > maxAmp) maxAmp = amp;
      }

      if (maxAmp == 0) return null;

      // Normalize relative to peak so the waveform fills the available height
      final normalized = [for (final v in raw) (v / maxAmp).clamp(0.0, 1.0)];
      _waveformCache[trackId] = normalized;

      // Clean up temp file
      try {
        if (waveOutFile.existsSync()) await waveOutFile.delete();
      } catch (_) {}

      return normalized;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Private
  // ─────────────────────────────────────────────────────────────

  BehaviorSubject<TrackState> _getOrCreateSubject(String trackId) {
    final existing = _subjects[trackId];
    if (existing != null && !existing.isClosed) return existing;

    final cached = _cache[trackId];
    final seed = cached != null
        ? TrackState(
            status: cached.status,
            position: cached.position,
            duration: cached.duration,
          )
        : const TrackState.initial();

    final subject = BehaviorSubject.seeded(seed);
    _subjects[trackId] = subject;

    return subject;
  }

  void _emitToSubject(String trackId, TrackState state) {
    final subject = _subjects[trackId];

    if (subject != null && !subject.isClosed) subject.add(state);
  }

  Future<void> _cacheActiveTrack() async {
    final currentId = _activeTrackId;
    if (currentId == null) return;

    await _cancelPlayerSubscriptions();
    await _player.pause();

    final cached = _cache[currentId];
    if (cached == null) return;

    cached
      ..position = _player.position
      ..duration = _player.duration ?? Duration.zero
      ..status = PlaybackStatus.paused;

    _emitToSubject(
      currentId,
      TrackState(
        status: PlaybackStatus.paused,
        position: cached.position,
        duration: cached.duration,
      ),
    );
  }

  Future<void> _loadTrack(String trackId, String path) async {
    _activeTrackId = trackId;
    _activeTrackSubject.add(trackId);

    final cached = _cache[trackId];
    _emitToSubject(
      trackId,
      TrackState(
        status: PlaybackStatus.loading,
        position: cached?.position ?? Duration.zero,
        duration: cached?.duration ?? Duration.zero,
      ),
    );

    await _player.load(path);
    await _player.setSpeed(_speed);

    if (cached != null && cached.position > Duration.zero) {
      cached.status.isCompleted
          ? await _player.seek(Duration.zero)
          : await _player.seek(cached.position);
    }

    _subscribeToPlayer(trackId);
  }

  void _subscribeToPlayer(String trackId) {
    _statusSub = _player.statusStream.listen((playbackStatus) {
      if (_activeTrackId != trackId) return;
      _emitToSubject(
        trackId,
        TrackState(
          status: playbackStatus,
          position: _player.position,
          duration: _player.duration ?? Duration.zero,
        ),
      );
    });

    _positionSub = _player.positionStream.listen((position) {
      if (_activeTrackId != trackId) return;
      _emitToSubject(
        trackId,
        TrackState(
          status: _player.status,
          position: position,
          duration: _player.duration ?? Duration.zero,
        ),
      );
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (_activeTrackId != trackId || duration == null) return;
      _emitToSubject(
        trackId,
        TrackState(
          status: _player.status,
          position: _player.position,
          duration: duration,
        ),
      );
    });
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
