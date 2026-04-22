import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart'
    as jap;
import 'package:voice_notes/core/packages/player/audio_player_service.dart';
import 'package:voice_notes/core/packages/player/just_audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JustAudioPlayerService', () {
    late jap.JustAudioPlatform originalPlatform;

    setUp(() {
      originalPlatform = jap.JustAudioPlatform.instance;
    });

    tearDown(() {
      jap.JustAudioPlatform.instance = originalPlatform;
    });

    test('disposes lingering native players on startup', () async {
      final platform = _FakeJustAudioPlatform();
      jap.JustAudioPlatform.instance = platform;

      final service = JustAudioPlayerService();
      await service.dispose();

      expect(platform.disposeAllPlayersCalls, 1);
    });
  });

  group('mapJustAudioPlayerState', () {
    test('completed wins over playing', () {
      final status = mapJustAudioPlayerState(
        ja.PlayerState(true, ja.ProcessingState.completed),
      );

      expect(status, PlaybackStatus.completed);
    });

    test('maps loading and buffering to loading', () {
      final loadingStatus = mapJustAudioPlayerState(
        ja.PlayerState(false, ja.ProcessingState.loading),
      );
      final bufferingStatus = mapJustAudioPlayerState(
        ja.PlayerState(true, ja.ProcessingState.buffering),
      );

      expect(loadingStatus, PlaybackStatus.loading);
      expect(bufferingStatus, PlaybackStatus.loading);
    });

    test('maps ready state based on playing flag', () {
      final pausedStatus = mapJustAudioPlayerState(
        ja.PlayerState(false, ja.ProcessingState.ready),
      );
      final playingStatus = mapJustAudioPlayerState(
        ja.PlayerState(true, ja.ProcessingState.ready),
      );

      expect(pausedStatus, PlaybackStatus.paused);
      expect(playingStatus, PlaybackStatus.playing);
    });
  });
}

class _FakeJustAudioPlatform extends jap.JustAudioPlatform {
  int disposeAllPlayersCalls = 0;

  @override
  Future<jap.AudioPlayerPlatform> init(jap.InitRequest request) async {
    return _FakeAudioPlayerPlatform(request.id);
  }

  @override
  Future<jap.DisposePlayerResponse> disposePlayer(
    jap.DisposePlayerRequest request,
  ) async {
    return jap.DisposePlayerResponse();
  }

  @override
  Future<jap.DisposeAllPlayersResponse> disposeAllPlayers(
    jap.DisposeAllPlayersRequest request,
  ) async {
    disposeAllPlayersCalls++;
    return jap.DisposeAllPlayersResponse();
  }
}

class _FakeAudioPlayerPlatform extends jap.AudioPlayerPlatform {
  _FakeAudioPlayerPlatform(super.id);

  @override
  Stream<jap.PlaybackEventMessage> get playbackEventMessageStream =>
      const Stream<jap.PlaybackEventMessage>.empty();
}
