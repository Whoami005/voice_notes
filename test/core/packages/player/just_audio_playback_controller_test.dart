import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';
import 'package:voice_notes/core/packages/player/controller/just_audio_playback_controller.dart';
import 'package:voice_notes/core/packages/player/controller/just_audio_playback_waveform.dart';

void main() {
  group('sampleNormalizedAmplitudes', () {
    test('keeps short waveforms by clamping sample step to one', () {
      final values = <double>[1, 2, 3];

      final result = sampleNormalizedAmplitudes(
        length: values.length,
        readAmplitude: values.elementAt,
      );

      expect(result, [1 / 3, 2 / 3, 1]);
    });

    test('returns null for zero-amplitude waveform', () {
      final result = sampleNormalizedAmplitudes(
        length: 3,
        readAmplitude: (_) => 0,
      );

      expect(result, isNull);
    });

    test('normalizes amplitudes into 0..1 range', () {
      final values = <double>[2, 4, 8];

      final result = sampleNormalizedAmplitudes(
        length: values.length,
        readAmplitude: values.elementAt,
      );

      expect(result, isNotNull);
      expect(result, everyElement(inInclusiveRange(0.0, 1.0)));
      expect(result!.last, 1);
    });
  });

  group('JustAudioPlaybackController', () {
    late _FakeAudioPlayerService player;
    late JustAudioPlaybackController controller;

    setUp(() {
      player = _FakeAudioPlayerService();
      controller = JustAudioPlaybackController.withPlayer(player);
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('replays active completed track from zero', () async {
      controller.register(
        'track',
        CachedTrackState(
          absolutePath: '/audio/track.wav',
          title: 'Track title',
          folderId: 'folder',
        ),
      );

      await controller.play('track');
      player.status = PlaybackStatus.completed;

      await controller.play('track');

      expect(player.seekCalls, [Duration.zero]);
      expect(player.playCalls, 2);
    });

    test(
      'keeps playing status while active track buffers during seek',
      () async {
        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/track.wav',
            title: 'Track title',
            folderId: 'folder',
          ),
        );

        final states = <TrackState>[];
        final sub = controller.trackStateStream('track').listen(states.add);

        await controller.play('track');
        player.pushStatus(
          PlaybackStatus.playing,
          position: const Duration(seconds: 1),
          duration: const Duration(seconds: 10),
        );
        await Future<void>.delayed(Duration.zero);

        player.pushStatus(
          PlaybackStatus.loading,
          position: const Duration(seconds: 2),
          duration: const Duration(seconds: 10),
        );
        await Future<void>.delayed(Duration.zero);

        expect(states.last.status, PlaybackStatus.playing);
        expect(states.last.position, const Duration(seconds: 2));

        await sub.cancel();
      },
    );

    test(
      'switching tracks caches previous position, duration and paused status',
      () async {
        controller.register(
          'first',
          CachedTrackState(
            absolutePath: '/audio/first.wav',
            title: 'First track',
            folderId: 'folder',
          ),
        );
        controller.register(
          'second',
          CachedTrackState(
            absolutePath: '/audio/second.wav',
            title: 'Second track',
            folderId: 'folder',
          ),
        );

        await controller.play('first');
        player
          ..status = PlaybackStatus.playing
          ..position = const Duration(seconds: 3)
          ..duration = const Duration(seconds: 10);

        await controller.play('second');

        final firstState = await controller.trackStateStream('first').first;

        expect(
          firstState,
          const TrackState(
            status: PlaybackStatus.paused,
            position: Duration(seconds: 3),
            duration: Duration(seconds: 10),
          ),
        );
      },
    );

    test(
      'register updates track metadata without losing cached progress',
      () async {
        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/original.wav',
            duration: const Duration(seconds: 10),
            title: 'Original track',
            folderId: 'folder',
          ),
        );
        await controller.seek('track', const Duration(seconds: 5));

        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/updated.wav',
            duration: const Duration(seconds: 20),
            title: 'Updated track',
            folderId: 'folder',
          ),
        );

        await controller.play('track');

        expect(player.loadPaths, ['/audio/updated.wav']);
        expect(player.loadInitialPositions, [const Duration(seconds: 5)]);
      },
    );

    test(
      'register does not overwrite a known duration with zero duration',
      () async {
        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/original.wav',
            duration: const Duration(seconds: 10),
            title: 'Original track',
            folderId: 'folder',
          ),
        );

        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/original.wav',
            duration: Duration.zero,
            title: 'Original track',
            folderId: 'folder',
          ),
        );

        expect(
          await controller.trackStateStream('track').first,
          const TrackState(
            status: PlaybackStatus.init,
            position: Duration.zero,
            duration: Duration(seconds: 10),
          ),
        );
      },
    );

    test(
      'seeking inactive track updates cached state without touching player seek',
      () async {
        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/track.wav',
            title: 'Track title',
            folderId: 'folder',
          ),
        );

        await controller.seek('track', const Duration(seconds: 2));

        expect(player.seekCalls, isEmpty);
        expect(
          await controller.trackStateStream('track').first,
          const TrackState(
            status: PlaybackStatus.init,
            position: Duration(seconds: 2),
            duration: Duration.zero,
          ),
        );
      },
    );

    test(
      'play publishes a visible playback session with track metadata',
      () async {
        final sessions = <PlaybackSessionState>[];
        final sessionSub = controller.sessionStream.listen(sessions.add);

        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/track.wav',
            title: 'Track title',
            folderId: 'folder',
          ),
        );
        await controller.play('track');
        player.pushStatus(
          PlaybackStatus.playing,
          position: const Duration(seconds: 1),
          duration: const Duration(seconds: 10),
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          controller.session,
          const PlaybackSessionState(
            trackId: 'track',
            title: 'Track title',
            folderId: 'folder',
            status: PlaybackStatus.playing,
            position: Duration(seconds: 1),
            duration: Duration(seconds: 10),
            speed: 1,
          ),
        );
        expect(controller.session.isVisible, isTrue);
        expect(sessions.last, controller.session);

        await sessionSub.cancel();
      },
    );

    test('pause hides session but keeps paused track state', () async {
      controller.register(
        'track',
        CachedTrackState(
          absolutePath: '/audio/track.wav',
          title: 'Track title',
          folderId: 'folder',
        ),
      );
      final states = <TrackState>[];
      final trackSub = controller.trackStateStream('track').listen(states.add);

      await controller.play('track');
      player.pushStatus(
        PlaybackStatus.playing,
        position: const Duration(seconds: 2),
        duration: const Duration(seconds: 10),
      );
      await Future<void>.delayed(Duration.zero);

      await controller.pause();
      await Future<void>.delayed(Duration.zero);

      expect(player.pauseCalls, 1);
      expect(controller.session, const PlaybackSessionState.hidden());
      expect(
        states.last,
        const TrackState(
          status: PlaybackStatus.paused,
          position: Duration(seconds: 2),
          duration: Duration(seconds: 10),
        ),
      );

      await trackSub.cancel();
    });

    test(
      'clearSession stops active playback and preserves cached progress',
      () async {
        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/track.wav',
            title: 'Track title',
            folderId: 'folder',
          ),
        );
        await controller.play('track');
        player
          ..status = PlaybackStatus.playing
          ..position = const Duration(seconds: 3)
          ..duration = const Duration(seconds: 10);

        await controller.clearSession();

        expect(player.stopCalls, 1);
        expect(controller.session, const PlaybackSessionState.hidden());

        await controller.play('track');

        expect(player.loadInitialPositions.last, const Duration(seconds: 3));
      },
    );

    test('completed playback hides the global session', () async {
      controller.register(
        'track',
        CachedTrackState(
          absolutePath: '/audio/track.wav',
          title: 'Track title',
          folderId: 'folder',
        ),
      );
      final states = <TrackState>[];
      final trackSub = controller.trackStateStream('track').listen(states.add);

      await controller.play('track');
      player.pushStatus(
        PlaybackStatus.playing,
        position: const Duration(seconds: 8),
        duration: const Duration(seconds: 10),
      );
      await Future<void>.delayed(Duration.zero);
      player.pushStatus(
        PlaybackStatus.completed,
        position: const Duration(seconds: 10),
        duration: const Duration(seconds: 10),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.session, const PlaybackSessionState.hidden());
      expect(
        states.last,
        const TrackState(
          status: PlaybackStatus.completed,
          position: Duration(seconds: 10),
          duration: Duration(seconds: 10),
        ),
      );

      await trackSub.cancel();
    });

    test('setSpeed refreshes the visible playback session', () async {
      controller.register(
        'track',
        CachedTrackState(
          absolutePath: '/audio/track.wav',
          title: 'Track title',
          folderId: 'folder',
        ),
      );

      await controller.play('track');
      player.pushStatus(
        PlaybackStatus.playing,
        position: const Duration(seconds: 1),
        duration: const Duration(seconds: 10),
      );
      await Future<void>.delayed(Duration.zero);

      await controller.setSpeed(1.5);

      expect(player.speed, 1.5);
      expect(
        controller.session,
        const PlaybackSessionState(
          trackId: 'track',
          title: 'Track title',
          folderId: 'folder',
          status: PlaybackStatus.playing,
          position: Duration(seconds: 1),
          duration: Duration(seconds: 10),
          speed: 1.5,
        ),
      );
      expect(controller.session.isVisible, isTrue);
    });

    test(
      'setSpeed keeps a hidden session hidden while updating speed',
      () async {
        expect(controller.session, const PlaybackSessionState.hidden());

        await controller.setSpeed(1.5);

        expect(player.speed, 1.5);
        expect(
          controller.session,
          const PlaybackSessionState.hidden(speed: 1.5),
        );
        expect(controller.session.isVisible, isFalse);
      },
    );

    test('register with a new path invalidates cached waveform data', () async {
      final requestedPaths = <String>[];
      controller = JustAudioPlaybackController.withPlayer(
        player,
        waveformLoader: (_, path) async {
          requestedPaths.add(path);
          return path.contains('original')
              ? const [0.2, 0.4, 1.0]
              : const [0.1, 0.6, 1.0];
        },
      );

      controller.register(
        'track',
        CachedTrackState(
          absolutePath: '/audio/original.wav',
          title: 'Track title',
          folderId: 'folder',
        ),
      );

      expect(await controller.getWaveform('track'), const [0.2, 0.4, 1.0]);

      controller.register(
        'track',
        CachedTrackState(
          absolutePath: '/audio/updated.wav',
          title: 'Track title',
          folderId: 'folder',
        ),
      );

      expect(await controller.getWaveform('track'), const [0.1, 0.6, 1.0]);
      expect(requestedPaths, ['/audio/original.wav', '/audio/updated.wav']);
    });

    test(
      'stale waveform requests resolve to null after path changes',
      () async {
        final requestedPaths = <String>[];
        final staleWaveform = Completer<List<double>?>();
        controller = JustAudioPlaybackController.withPlayer(
          player,
          waveformLoader: (_, path) {
            requestedPaths.add(path);
            if (path.contains('original')) return staleWaveform.future;
            return Future.value(const [0.3, 0.9, 1.0]);
          },
        );

        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/original.wav',
            title: 'Track title',
            folderId: 'folder',
          ),
        );

        final staleFuture = controller.getWaveform('track');

        controller.register(
          'track',
          CachedTrackState(
            absolutePath: '/audio/updated.wav',
            title: 'Track title',
            folderId: 'folder',
          ),
        );

        final freshFuture = controller.getWaveform('track');
        staleWaveform.complete(const [0.1, 0.2, 1.0]);

        expect(await staleFuture, isNull);
        expect(await freshFuture, const [0.3, 0.9, 1.0]);
        expect(requestedPaths, ['/audio/original.wav', '/audio/updated.wav']);
      },
    );
  });
}

class _FakeAudioPlayerService implements AudioPlayerService {
  final StreamController<PlaybackStatus> _statusController =
      StreamController<PlaybackStatus>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();

  final List<String> loadPaths = <String>[];
  final List<Duration> loadInitialPositions = <Duration>[];
  final List<Duration> seekCalls = <Duration>[];

  PlaybackStatus status = PlaybackStatus.init;
  Duration position = Duration.zero;
  Duration? duration;
  double speed = 1;
  int playCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Future<Duration?> load(
    String absolutePath, {
    Duration initialPosition = Duration.zero,
  }) async {
    loadPaths.add(absolutePath);
    loadInitialPositions.add(initialPosition);
    position = initialPosition;
    return duration;
  }

  @override
  Future<void> play() async {
    playCalls++;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> seek(Duration position) async {
    this.position = position;
    seekCalls.add(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    this.speed = speed;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await _positionController.close();
    await _durationController.close();
  }

  void pushStatus(
    PlaybackStatus status, {
    Duration? position,
    Duration? duration,
  }) {
    this.status = status;
    if (position != null) this.position = position;
    if (duration != null) this.duration = duration;

    _statusController.add(status);
  }
}
