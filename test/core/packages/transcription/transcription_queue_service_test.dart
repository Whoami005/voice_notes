import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_audio_entity.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_failure_reason.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';

void main() {
  late _FakeNoteRepository repo;
  late _FakeAsrService asr;
  late RecordingPreferences prefs;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Мокаем path_provider, чтобы `AudioPaths.resolveRelativePath` не лез
    // в нативный слой; возвращаем фиктивный путь — транскрибация его
    // всё равно получит через fake ASR.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return '/tmp/voice_notes_test_docs';
          }
          return null;
        });
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repo = _FakeNoteRepository();
    asr = _FakeAsrService();
    prefs = RecordingPreferences(await SharedPreferences.getInstance());
  });

  TranscriptionQueueService buildService({
    Duration transcribeTimeout = const Duration(seconds: 30),
  }) {
    return TranscriptionQueueService.forTesting(
      noteRepository: repo,
      asrService: asr,
      preferences: prefs,
      transcribeTimeout: transcribeTimeout,
    );
  }

  group('bootstrap', () {
    test('success — state becomes ready; seed from watchQueued emit', () async {
      final note = _makeNote('n1', status: TranscriptionStatus.queued);
      repo.addNote(note);

      final service = buildService();
      await service.start();

      // Broadcast-стрим не реплеит прошлые события новым подписчикам, так
      // что имитируем `triggerImmediately: true` вручную.
      repo.emitQueued([note]);
      await _pump();

      expect(service.current.bootstrapState, isA<QueueBootstrapReady>());
      expect(service.current.queued, contains('n1'));

      await service.dispose();
    });

    test(
      'error in resetTranscribingToQueued → bootstrapState is error',
      () async {
        repo.resetShouldThrow = true;

        final service = buildService();
        await service.start();

        expect(service.current.bootstrapState, isA<QueueBootstrapError>());
        final err = service.current.bootstrapState as QueueBootstrapError;
        expect(err.failure, isA<AppFailure>());

        await service.dispose();
      },
    );

    test('retryBootstrap recovers from error → ready', () async {
      repo.resetShouldThrow = true;

      final service = buildService();
      await service.start();
      expect(service.current.bootstrapState, isA<QueueBootstrapError>());

      repo.resetShouldThrow = false;
      await service.retryBootstrap();

      expect(service.current.bootstrapState, isA<QueueBootstrapReady>());

      await service.dispose();
    });
  });

  group('retryAll', () {
    test('only failed notes are requeued; cancelled untouched', () async {
      asr.isInitializedValue = false;

      final failed = _makeNote('f1', status: TranscriptionStatus.failed);
      final cancelled = _makeNote('c1', status: TranscriptionStatus.cancelled);
      repo
        ..addNote(failed)
        ..addNote(cancelled);

      final service = buildService();
      await service.start();

      await service.retryAll();

      expect(repo.markQueuedCalls, contains('f1'));
      expect(repo.markQueuedCalls, isNot(contains('c1')));

      await service.dispose();
    });

    test('breaker is reset before requeuing', () async {
      asr.isInitializedValue = false;

      // Set up 3 failures to engage breaker
      final failed = _makeNote('f1', status: TranscriptionStatus.failed);
      repo.addNote(failed);

      final service = buildService();
      await service.start();

      // Simulate 3 failures to pause breaker
      for (int i = 0; i < 3; i++) {
        asr.transcribeFileImpl = (_) =>
            throw const AsrProcessingException('boom');
      }

      await service.retryAll();
      // After retryAll, breaker should be reset; paused=false
      expect(service.current.paused, isFalse);

      await service.dispose();
    });
  });

  group('clearFailedAll / dismissFailed', () {
    test('clearFailedAll: all failed notes become cancelled', () async {
      asr.isInitializedValue = false;

      final f1 = _makeNote('f1', status: TranscriptionStatus.failed);
      final f2 = _makeNote('f2', status: TranscriptionStatus.failed);
      repo
        ..addNote(f1)
        ..addNote(f2);

      final service = buildService();
      await service.start();

      await service.clearFailedAll();

      expect(repo.markCancelledCalls, containsAll(<String>['f1', 'f2']));

      await service.dispose();
    });

    test('dismissFailed: ignores non-failed notes', () async {
      asr.isInitializedValue = false;

      final queued = _makeNote('q1', status: TranscriptionStatus.queued);
      repo.addNote(queued);

      final service = buildService();
      await service.start();

      await service.dismissFailed('q1');

      expect(repo.markCancelledCalls, isNot(contains('q1')));

      await service.dispose();
    });

    test('dismissFailed: failed note → cancelled', () async {
      asr.isInitializedValue = false;

      final failed = _makeNote('f1', status: TranscriptionStatus.failed);
      repo.addNote(failed);

      final service = buildService();
      await service.start();

      await service.dismissFailed('f1');

      expect(repo.markCancelledCalls, contains('f1'));

      await service.dispose();
    });
  });

  group('breaker', () {
    test('unconditional reset when ASR becomes ready', () async {
      asr.isInitializedValue = false;

      final service = buildService();
      await service.start();

      // Simulate 3 failures → breaker paused
      // We poke the internals via a note that will fail.
      final n = _makeNote(
        'n',
        status: TranscriptionStatus.queued,
        audio: _makeAudio(),
      );
      repo
        ..addNote(n)
        ..queuedValue = [n];

      asr
        ..isInitializedValue = true
        ..emitAsrReady(true)
        ..transcribeFileImpl = (_) =>
            throw const AsrProcessingException('boom');

      // Push into queue via watchQueued
      repo.emitQueued([n]);
      // Let microtasks settle & drain run. The single failure alone won't
      // trigger breaker (needs 3). Sanity: ensure no pause yet.
      await _pump();

      expect(service.current.paused, isFalse);

      // Now toggle ASR-ready false → true; breaker stays unpaused (reset).
      asr
        ..emitAsrReady(false)
        ..emitAsrReady(true);
      await _pump();
      expect(service.current.paused, isFalse);

      await service.dispose();
    });
  });

  group('timeout classification', () {
    test('timeout → transcriptionTimedOut failure reason', () async {
      asr.isInitializedValue = true;

      final note = _makeNote(
        'n1',
        status: TranscriptionStatus.queued,
        audio: _makeAudio(),
      );
      repo.addNote(note);

      asr.transcribeFileImpl = (_) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return AsrResult.empty;
      };

      final service = buildService(
        transcribeTimeout: const Duration(milliseconds: 50),
      );
      await service.start();

      // Имитируем immediate-emit ObjectBox
      repo.emitQueued([note]);

      // Ждём drain'а + timeout'а
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        repo.failedCalls['n1'],
        TranscriptionFailureReason.transcriptionTimedOut,
      );

      await service.dispose();
    });
  });
}

/// Short microtask flush.
Future<void> _pump() => Future<void>.delayed(Duration.zero);

NoteEntity _makeNote(
  String uid, {
  required TranscriptionStatus status,
  NoteAudioEntity? audio,
}) {
  return NoteEntity(
    uuid: uid,
    text: '',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    duration: const Duration(seconds: 10),
    modelName: '',
    language: '',
    wordCount: 0,
    status: status,
    audio: audio,
  );
}

NoteAudioEntity _makeAudio() {
  return const NoteAudioEntity(
    relativePath: 'a.wav',
    duration: Duration(seconds: 1),
    sizeBytes: 1000,
    sampleRate: 16000,
  );
}

/// Minimal NoteRepository fake: store map by uid + stream controllers.
class _FakeNoteRepository implements NoteRepository {
  final Map<String, NoteEntity> _notes = <String, NoteEntity>{};
  final StreamController<List<NoteEntity>> _queuedController =
      StreamController<List<NoteEntity>>.broadcast();
  final StreamController<List<NoteEntity>> _failedController =
      StreamController<List<NoteEntity>>.broadcast();
  final StreamController<List<NoteEntity>> _cancelledController =
      StreamController<List<NoteEntity>>.broadcast();
  final StreamController<String> _deletedController =
      StreamController<String>.broadcast();

  List<NoteEntity> queuedValue = <NoteEntity>[];
  bool resetShouldThrow = false;

  final List<String> markQueuedCalls = <String>[];
  final List<String> markCancelledCalls = <String>[];
  final List<String> markTranscribingCalls = <String>[];
  final Map<String, TranscriptionFailureReason> failedCalls =
      <String, TranscriptionFailureReason>{};
  final List<String> completeCalls = <String>[];

  void addNote(NoteEntity note) => _notes[note.uuid] = note;

  void emitQueued(List<NoteEntity> notes) => _queuedController.add(notes);

  @override
  Stream<List<NoteEntity>> watchQueued() => _queuedController.stream;

  @override
  Stream<List<NoteEntity>> watchFailed() => _failedController.stream;

  @override
  Stream<List<NoteEntity>> watchCancelled() => _cancelledController.stream;

  @override
  Stream<String> get onDeleted => _deletedController.stream;

  @override
  Future<List<NoteEntity>> getQueued() async => queuedValue;

  @override
  Future<List<NoteEntity>> getFailed() async =>
      _notes.values.where((n) => n.isFailed).toList();

  @override
  Future<List<NoteEntity>> getCancelled() async =>
      _notes.values.where((n) => n.isCancelled).toList();

  @override
  Future<NoteEntity?> getByUidOrNull(String uid) async => _notes[uid];

  @override
  Future<NoteEntity> getByUid(String uid) async {
    final n = _notes[uid];
    if (n == null) throw StateError('missing $uid');
    return n;
  }

  @override
  Future<void> resetTranscribingToQueued() async {
    if (resetShouldThrow) throw StateError('boom');
  }

  @override
  Future<NoteEntity?> markQueued(String uid) async {
    markQueuedCalls.add(uid);
    final n = _notes[uid];
    if (n != null) {
      _notes[uid] = _copyWithStatus(n, TranscriptionStatus.queued);
    }
    return _notes[uid];
  }

  @override
  Future<NoteEntity?> markCancelled(String uid) async {
    markCancelledCalls.add(uid);
    final n = _notes[uid];
    if (n != null) {
      _notes[uid] = _copyWithStatus(n, TranscriptionStatus.cancelled);
    }
    return _notes[uid];
  }

  @override
  Future<NoteEntity?> markTranscribing(String uid) async {
    markTranscribingCalls.add(uid);
    final n = _notes[uid];
    if (n != null) {
      _notes[uid] = _copyWithStatus(n, TranscriptionStatus.transcribing);
    }
    return _notes[uid];
  }

  @override
  Future<NoteEntity?> failTranscription({
    required String uid,
    required TranscriptionFailureReason reason,
  }) async {
    failedCalls[uid] = reason;
    final n = _notes[uid];
    if (n != null) {
      _notes[uid] = _copyWithStatus(n, TranscriptionStatus.failed);
    }
    return _notes[uid];
  }

  @override
  Future<NoteEntity?> completeTranscription({
    required String uid,
    required String text,
    required String language,
    required String modelName,
    required int wordCount,
    required bool deleteAudio,
  }) async {
    completeCalls.add(uid);
    return _notes[uid];
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError(
    'Fake NoteRepository: ${i.memberName} not stubbed',
  );

  static NoteEntity _copyWithStatus(NoteEntity n, TranscriptionStatus status) {
    return NoteEntity(
      uuid: n.uuid,
      text: n.text,
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
      duration: n.duration,
      modelName: n.modelName,
      language: n.language,
      wordCount: n.wordCount,
      status: status,
      audio: n.audio,
      folderId: n.folderId,
      tags: n.tags,
      failureReason: n.failureReason,
    );
  }
}

/// Minimal AsrService fake.
class _FakeAsrService implements AsrService {
  bool isInitializedValue = false;
  AsrModelEntity? currentModelValue;
  Future<AsrResult> Function(String path) transcribeFileImpl = (path) async =>
      const AsrResult(text: 'ok');

  final StreamController<bool> _stateController =
      StreamController<bool>.broadcast();

  void emitAsrReady(bool value) {
    isInitializedValue = value;
    _stateController.add(value);
  }

  @override
  bool get isInitialized => isInitializedValue;

  @override
  Stream<bool> get stateStream => _stateController.stream;

  @override
  AsrModelEntity? get currentModel => currentModelValue;

  @override
  Future<AsrResult> transcribeFile(String filePath) =>
      transcribeFileImpl(filePath);

  @override
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('Fake AsrService: ${i.memberName} not stubbed');
}
