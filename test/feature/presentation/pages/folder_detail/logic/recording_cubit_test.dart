import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/audio/audio_recording_service.dart';
import 'package:voice_notes/core/packages/note_ingestion/note_ingestion_service.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/logic/recording_cubit.dart';

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('RecordingCubit quick record', () {
    test(
      'emits waiting state until priority transcription actually starts',
      () async {
        final recordingService = _FakeAudioRecordingService();
        final queueController = _FakeTranscriptionQueueController()
          ..currentSnapshot = const TranscriptionQueueSnapshot(
            processing: 'queued-note',
          );
        final transcribeCompleter = Completer<AsrResult>();
        void Function()? onStartedCallback;
        queueController.transcribeFileImpl =
            (_, {required audioDurationHint, onStarted}) {
              onStartedCallback = onStarted;
              return transcribeCompleter.future;
            };
        final noteRepository = _FakeNoteRepository();
        final cubit = RecordingCubit(
          recordingService: recordingService,
          queueController: queueController,
          noteRepository: noteRepository,
          playbackController: _FakePlaybackController(),
          ingestionService: NoteIngestionService(
            noteRepository: noteRepository,
          ),
        );

        await cubit.startRecording();
        await cubit.stopRecording();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, isA<RecordingWaitingTranscriptionSlotState>());

        onStartedCallback!();
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, isA<RecordingTranscribingState>());

        final errorFuture = expectLater(
          cubit.stream,
          emitsThrough(isA<RecordingErrorState>()),
        );
        transcribeCompleter.completeError(
          const AsrProcessingException('boom'),
          StackTrace.current,
        );
        await errorFuture;

        await cubit.close();
        await recordingService.disposeFake();
      },
    );

    test('maps priority ASR not-ready failure to noModelSelected', () async {
      final recordingService = _FakeAudioRecordingService();
      final queueController = _FakeTranscriptionQueueController()
        ..transcribeFileImpl = (_, {required audioDurationHint, onStarted}) {
          throw const AsrNotInitializedException();
        };
      final noteRepository = _FakeNoteRepository();
      final cubit = RecordingCubit(
        recordingService: recordingService,
        queueController: queueController,
        noteRepository: noteRepository,
        playbackController: _FakePlaybackController(),
        ingestionService: NoteIngestionService(noteRepository: noteRepository),
      );

      final errorState = expectLater(
        cubit.stream,
        emitsThrough(isA<RecordingErrorState>()),
      );

      await cubit.startRecording();
      await cubit.stopRecording();
      await errorState;

      final state = cubit.state;
      expect(state, isA<RecordingErrorState>());
      final failure = (state as RecordingErrorState).failure;
      expect(failure, const RecordingFailure.noModelSelected());
      expect(queueController.transcribeCalls, ['/tmp/quick.wav']);

      await cubit.close();
      await recordingService.disposeFake();
    });
  });
}

class _FakeAudioRecordingService implements AudioRecordingService {
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Duration get currentDuration => const Duration(seconds: 1);

  @override
  Future<void> startRecording({
    required String noteUuid,
    void Function()? onMaxDurationReached,
  }) async {}

  @override
  Future<RecordingResult> stopRecording() async {
    return const RecordingResult(
      filePath: '/tmp/quick.wav',
      duration: Duration(seconds: 1),
    );
  }

  @override
  Future<void> cancelRecording() async {}

  Future<void> disposeFake() async {
    await _amplitudeController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Fake AudioRecordingService: ${invocation.memberName} not stubbed',
  );
}

class _FakeTranscriptionQueueController
    implements TranscriptionQueueController {
  final StreamController<TranscriptionQueueSnapshot> _snapshotController =
      StreamController<TranscriptionQueueSnapshot>.broadcast();

  TranscriptionQueueSnapshot currentSnapshot =
      const TranscriptionQueueSnapshot();

  Future<AsrResult> Function(
    String filePath, {
    required Duration audioDurationHint,
    void Function()? onStarted,
  })
  transcribeFileImpl = (_, {required audioDurationHint, onStarted}) async =>
      const AsrResult(text: 'ok');

  final List<String> transcribeCalls = <String>[];

  @override
  Stream<TranscriptionQueueSnapshot> get snapshots =>
      _snapshotController.stream;

  @override
  TranscriptionQueueSnapshot get current => currentSnapshot;

  @override
  Future<AsrResult> transcribePriorityFile(
    String filePath, {
    required Duration audioDurationHint,
    void Function()? onStarted,
  }) {
    transcribeCalls.add(filePath);
    return transcribeFileImpl(
      filePath,
      audioDurationHint: audioDurationHint,
      onStarted: onStarted,
    );
  }

  @override
  Future<void> dispose() async {
    await _snapshotController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Fake TranscriptionQueueController: ${invocation.memberName} not stubbed',
  );
}

class _FakePlaybackController implements AudioPlaybackController {
  @override
  PlaybackSessionState get session => const PlaybackSessionState.hidden();

  @override
  Stream<PlaybackSessionState> get sessionStream => const Stream.empty();

  @override
  Future<void> pause() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Fake AudioPlaybackController: ${invocation.memberName} not stubbed',
  );
}

class _FakeNoteRepository implements NoteRepository {
  @override
  Stream<String> get onDeleted => const Stream.empty();

  @override
  Future<NoteEntity> create({
    required String text,
    required Duration duration,
    required String modelName,
    required String language,
    required int wordCount,
    String? uid,
    String? folderUid,
    List<String> tagNames = const [],
    NoteAudioEntity? audio,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Fake NoteRepository: ${invocation.memberName} not stubbed',
  );
}
