import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_origin_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';
import 'package:voice_notes/feature/presentation/pages/note_detail/logic/note_playback_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotePlaybackCubit', () {
    late _FakeAudioPlaybackController controller;
    late NotePlaybackCubit cubit;

    setUpAll(() {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return '/tmp/voice_notes_test_docs';
            }

            return null;
          });
    });

    setUp(() {
      controller = _FakeAudioPlaybackController();
      cubit = NotePlaybackCubit(
        controller: controller,
        folderId: 'folder',
        noteId: 'track',
      );
    });

    tearDown(() async {
      await cubit.close();
      await controller.dispose();
    });

    test(
      'loadNote does not force ready before controller emits track state',
      () async {
        await cubit.loadNote(_note);

        expect(cubit.state.status.isSuccess, isTrue);
        expect(cubit.state.playbackStatus, PlaybackStatus.init);
        expect(cubit.state.duration, _note.origin.audio!.duration);
        expect(cubit.state.speed, controller.session.speed);
      },
    );

    test(
      'loadNote cancels previous track subscription before listening again',
      () async {
        await cubit.loadNote(_note);
        await cubit.loadNote(_note);

        expect(controller.trackListenCount, 2);
        expect(controller.trackCancelCount, 1);
      },
    );
  });
}

final NoteEntity _note = NoteEntity(
  uuid: 'track',
  folderId: 'folder',
  text: 'Track title',
  origin: const AudioNoteOriginEntity(
    sourceDuration: Duration(seconds: 5),
    audio: NoteAudioEntity(
      relativePath: 'audio/recordings/track.wav',
      sizeBytes: 1,
      sampleRate: 16000,
      duration: Duration(seconds: 5),
    ),
  ),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  status: TranscriptionStatus.completed,
);

class _FakeAudioPlaybackController implements AudioPlaybackController {
  _FakeAudioPlaybackController() {
    _trackController = StreamController<TrackState>.broadcast(
      onListen: () {
        trackListenCount++;
      },
      onCancel: () {
        trackCancelCount++;
      },
    );
  }

  late final StreamController<TrackState> _trackController;

  int trackListenCount = 0;
  int trackCancelCount = 0;

  @override
  PlaybackSessionState get session =>
      const PlaybackSessionState.hidden(speed: 1.25);

  @override
  Stream<PlaybackSessionState> get sessionStream => const Stream.empty();

  @override
  Stream<TrackState> trackStateStream(String trackId) =>
      _trackController.stream;

  @override
  void register(String trackId, CachedTrackState state) {}

  @override
  Future<List<double>?> getWaveform(String trackId) async => null;

  @override
  Future<void> dispose() async {
    await _trackController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
