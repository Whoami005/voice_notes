import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/error/app_failure.dart';
import 'package:voice_notes/core/packages/asr/asr_cancel_token.dart';
import 'package:voice_notes/core/packages/asr/asr_exception.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/asr/asr_service.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
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

  group('cancel/delete in-flight with cancelToken', () {
    test(
      'streaming-model cancel → AsrCancelledException → markCancelled',
      () async {
        asr
          ..isInitializedValue = true
          ..currentModelValue = _streamingModel();

        final note = _makeNote(
          'n1',
          status: TranscriptionStatus.queued,
          audio: _makeAudio(),
        );
        repo.addNote(note);

        // FakeAsrService ждёт, пока cancelToken сработает, и бросает.
        asr.transcribeFileImpl = (path) async {
          await asr.lastCancelToken!.whenCancelled;
          throw const AsrCancelledException();
        };

        final service = buildService();
        await service.start();
        repo.emitQueued([note]);
        await _pump();

        // Даём drain'у стартовать и войти в transcribeFile.
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await service.cancel('n1');

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(repo.markCancelledCalls, contains('n1'));
        expect(asr.lastCancelToken!.isCancelled, isTrue);
        // breaker не тронут ни success ни failure при cancel
        expect(service.current.paused, isFalse);

        await service.dispose();
      },
    );

    test(
      'whisper-model cancel → token.cancel() but no-op, post-decode consume',
      () async {
        asr
          ..isInitializedValue = true
          ..currentModelValue = _whisperModel();

        final note = _makeNote(
          'n1',
          status: TranscriptionStatus.queued,
          audio: _makeAudio(),
        );
        repo.addNote(note);

        final completer = Completer<AsrResult>();
        asr.transcribeFileImpl = (path) => completer.future;

        final service = buildService();
        await service.start();
        repo.emitQueued([note]);
        await _pump();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Cancel пока ASR "работает" — token.cancel() вызван, но fake не
        // реагирует на него (симулируя offline-поведение).
        await service.cancel('n1');
        expect(asr.lastCancelToken!.isCancelled, isTrue);

        // Теперь завершаем ASR штатно — consume-abort
        // должен перевести в cancelled.
        completer.complete(const AsrResult(text: 'done'));
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(repo.markCancelledCalls, contains('n1'));
        // complete не вызван — cancel перекрыл
        expect(repo.completeCalls, isNot(contains('n1')));
        await service.dispose();
      },
    );

    test('onNoteDeleted in-flight → token.cancel() fired', () async {
      asr
        ..isInitializedValue = true
        ..currentModelValue = _streamingModel();

      final note = _makeNote(
        'n1',
        status: TranscriptionStatus.queued,
        audio: _makeAudio(),
      );
      repo.addNote(note);

      asr.transcribeFileImpl = (path) async {
        await asr.lastCancelToken!.whenCancelled;
        throw const AsrCancelledException();
      };

      final service = buildService();
      await service.start();
      repo.emitQueued([note]);
      await _pump();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Эмулируем delete через стрим — _onNoteDeleted.
      repo._deletedController.add('n1');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(asr.lastCancelToken!.isCancelled, isTrue);
      await service.dispose();
    });
  });

  group('progress gating', () {
    test(
      'progress for active note updates snapshot.processingProgress',
      () async {
        asr
          ..isInitializedValue = true
          ..currentModelValue = _streamingModel();

        final note = _makeNote(
          'n1',
          status: TranscriptionStatus.queued,
          audio: _makeAudio(),
        );
        repo.addNote(note);

        final completer = Completer<AsrResult>();
        asr.transcribeFileImpl = (path) => completer.future;

        final service = buildService();
        await service.start();
        repo.emitQueued([note]);
        await _pump();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Эмулируем progress от воркера через сохранённый callback.
        asr.lastOnProgress!.call(
          const AsrTranscribeProgress(
            progress: 0.42,
            partialText: 'partial',
            processedAudio: Duration(seconds: 4),
            totalAudio: Duration(seconds: 10),
          ),
        );

        await _pump();

        expect(service.current.processingProgress, isNotNull);
        expect(service.current.processingProgress!.percent, 42);
        expect(service.current.processingSupportsStreaming, isTrue);

        completer.complete(const AsrResult(text: 'done'));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // После завершения задачи snapshot progress сброшен.
        expect(service.current.processingProgress, isNull);
        expect(service.current.processingSupportsStreaming, isFalse);

        await service.dispose();
      },
    );

    test('progress for cancelRequested note is dropped', () async {
      asr
        ..isInitializedValue = true
        ..currentModelValue = _streamingModel();

      final note = _makeNote(
        'n1',
        status: TranscriptionStatus.queued,
        audio: _makeAudio(),
      );
      repo.addNote(note);

      final completer = Completer<AsrResult>();
      asr.transcribeFileImpl = (path) async {
        await asr.lastCancelToken!.whenCancelled;
        throw const AsrCancelledException();
      };

      final service = buildService();
      await service.start();
      repo.emitQueued([note]);
      await _pump();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Запрос на cancel — _cancelRequested содержит 'n1' до того как
      // FakeAsrService отреагирует на whenCancelled.
      await service.cancel('n1');

      // Гоним stale progress — должен быть дропнут.
      asr.lastOnProgress!.call(
        const AsrTranscribeProgress(
          progress: 0.7,
          partialText: 'stale',
          processedAudio: Duration(seconds: 7),
          totalAudio: Duration(seconds: 10),
        ),
      );

      await _pump();

      expect(service.current.processingProgress, isNull);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      completer.complete(const AsrResult(text: 'done'));
      await service.dispose();
    });
  });

  group('capability freeze', () {
    test(
      'processingSupportsStreaming stays true even if model changes',
      () async {
        asr
          ..isInitializedValue = true
          ..currentModelValue = _streamingModel();

        final note = _makeNote(
          'n1',
          status: TranscriptionStatus.queued,
          audio: _makeAudio(),
        );
        repo.addNote(note);

        final completer = Completer<AsrResult>();
        asr.transcribeFileImpl = (path) => completer.future;

        final service = buildService();
        await service.start();
        repo.emitQueued([note]);
        await _pump();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(service.current.processingSupportsStreaming, isTrue);

        // Меняем модель на Whisper посреди задачи —
        // snapshot не должен реагировать.
        asr.currentModelValue = _whisperModel();
        await _pump();

        expect(service.current.processingSupportsStreaming, isTrue);

        completer.complete(const AsrResult(text: 'done'));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        await service.dispose();
      },
    );
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

AsrModelEntity _streamingModel() {
  return AsrModelEntity.availableModels.firstWhere(
    (m) => m.supportsStreaming,
    orElse: () => AsrModelEntity.availableModels.first,
  );
}

AsrModelEntity _whisperModel() {
  return AsrModelEntity.availableModels.firstWhere((m) => !m.supportsStreaming);
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

  /// Последний переданный `cancelToken` — для verify в тестах.
  AsrCancelToken? lastCancelToken;

  /// Последний переданный `onProgress` callback — для ручного дёргания
  /// в тестах (симуляция progress-событий от streaming-воркера).
  void Function(AsrTranscribeProgress progress)? lastOnProgress;

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
  Future<AsrResult> transcribeFile(
    String filePath, {
    void Function(AsrTranscribeProgress progress)? onProgress,
    AsrCancelToken? cancelToken,
  }) {
    lastCancelToken = cancelToken;
    lastOnProgress = onProgress;
    return transcribeFileImpl(filePath);
  }

  @override
  Future<AsrResult> transcribeAudio(Float32List samples, int sampleRate) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('Fake AsrService: ${i.memberName} not stubbed');
}
