import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/folder_playback_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FolderPlaybackCubit', () {
    late _FakeAudioPlaybackController controller;
    late _FakeNoteRepository noteRepository;

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
      noteRepository = _FakeNoteRepository();
    });

    tearDown(() async {
      await controller.dispose();
      await noteRepository.dispose();
    });

    test('close cancels screen subscriptions without clearing '
        'shared playback session', () async {
      final cubit = FolderPlaybackCubit(
        controller: controller,
        noteRepository: noteRepository,
        folderId: 'folder',
      );

      await cubit.close();

      expect(controller.clearSessionCalls, 0);
    });

    test('isPlaying reflects actual track playback status', () async {
      final note = _buildNote('track');
      final cubit = FolderPlaybackCubit(
        controller: controller,
        noteRepository: noteRepository,
        folderId: 'folder',
      );

      noteRepository.emitForFolder([note]);
      await Future<void>.delayed(Duration.zero);

      controller.pushTrackState(
        'track',
        const TrackState(
          status: PlaybackStatus.paused,
          duration: Duration(seconds: 5),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isPlaying('track'), isFalse);

      controller.pushTrackState(
        'track',
        const TrackState(
          status: PlaybackStatus.playing,
          position: Duration(seconds: 1),
          duration: Duration(seconds: 5),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isPlaying('track'), isTrue);

      await cubit.close();
    });
  });
}

class _FakeAudioPlaybackController implements AudioPlaybackController {
  final StreamController<PlaybackSessionState> _sessionController =
      StreamController<PlaybackSessionState>.broadcast();
  final Map<String, StreamController<TrackState>> _trackControllers =
      <String, StreamController<TrackState>>{};

  int clearSessionCalls = 0;
  final PlaybackSessionState _session = const PlaybackSessionState.hidden();

  void pushTrackState(String trackId, TrackState state) {
    _controllerFor(trackId).add(state);
  }

  StreamController<TrackState> _controllerFor(String trackId) {
    return _trackControllers.putIfAbsent(
      trackId,
      StreamController<TrackState>.broadcast,
    );
  }

  @override
  Stream<TrackState> trackStateStream(String trackId) =>
      _controllerFor(trackId).stream;

  @override
  PlaybackSessionState get session => _session;

  @override
  Stream<PlaybackSessionState> get sessionStream => _sessionController.stream;

  @override
  void register(String trackId, CachedTrackState state) {}

  @override
  Future<void> play(String trackId) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> togglePlayPause(String trackId) async {}

  @override
  Future<void> seek(String trackId, Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> clearSession() async => clearSessionCalls++;

  @override
  Future<List<double>?> getWaveform(String trackId) async => null;

  @override
  Future<void> dispose() async {
    await _sessionController.close();
    for (final controller in _trackControllers.values) {
      await controller.close();
    }
  }
}

class _FakeNoteRepository implements NoteRepository {
  final StreamController<List<NoteEntity>> _folderController =
      StreamController<List<NoteEntity>>.broadcast();

  void emitForFolder(List<NoteEntity> notes) {
    _folderController.add(notes);
  }

  @override
  Stream<List<NoteEntity>> watchByFolderId(String folderUid) =>
      _folderController.stream;

  @override
  Future<void> dispose() async {
    await _folderController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

NoteEntity _buildNote(String uuid) {
  final now = DateTime(2026);

  return NoteEntity(
    uuid: uuid,
    text: 'note',
    createdAt: now,
    updatedAt: now,
    duration: const Duration(seconds: 5),
    modelName: 'model',
    language: 'ru',
    wordCount: 1,
    status: TranscriptionStatus.completed,
    audio: const NoteAudioEntity(
      relativePath: 'audio/recordings/track.wav',
      sizeBytes: 1,
      sampleRate: 16000,
      duration: Duration(seconds: 5),
    ),
  );
}
