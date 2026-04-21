import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/packages/asr/asr_transcribe_progress.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/enums/transcription_status.dart';
import 'package:voice_notes/feature/presentation/pages/folder_detail/widgets/note_bubble.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class MockTranscriptionQueueCubit extends MockCubit<TranscriptionQueueState>
    implements TranscriptionQueueCubit {}

class MockAsrCubit extends MockCubit<AsrState> implements AsrCubit {}

class FakeTranscriptionQueueState extends Fake
    implements TranscriptionQueueState {}

class FakeAsrState extends Fake implements AsrState {}

void main() {
  late MockTranscriptionQueueCubit queueCubit;
  late MockAsrCubit asrCubit;

  setUpAll(() {
    registerFallbackValue(FakeTranscriptionQueueState());
    registerFallbackValue(FakeAsrState());
  });

  setUp(() {
    queueCubit = MockTranscriptionQueueCubit();
    asrCubit = MockAsrCubit();
    // Дефолтное состояние ASR — не готов. Реальный label берётся из
    // _transcribingLabel; если modelType null, использует generic.
    when(() => asrCubit.state).thenReturn(const AsrState(status: Status.init));
  });

  Future<void> pumpNoteBubble(
    WidgetTester tester, {
    required NoteEntity note,
    required TranscriptionQueueState queueState,
    VoidCallback? onCancel,
  }) {
    when(() => queueCubit.state).thenReturn(queueState);
    whenListen(queueCubit, Stream.value(queueState), initialState: queueState);

    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        theme: AppTheme.light,
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<TranscriptionQueueCubit>.value(value: queueCubit),
              BlocProvider<AsrCubit>.value(value: asrCubit),
            ],
            child: NoteBubble(note: note, onCancel: onCancel),
          ),
        ),
      ),
    );
  }

  NoteEntity makeNote({
    String uuid = 'n1',
    TranscriptionStatus status = TranscriptionStatus.transcribing,
  }) {
    return NoteEntity(
      uuid: uuid,
      text: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      duration: const Duration(seconds: 10),
      modelName: '',
      language: '',
      wordCount: 0,
      status: status,
    );
  }

  TranscriptionQueueState stateFor({
    String? processing,
    bool supportsStreaming = false,
    AsrTranscribeProgress? progress,
  }) {
    return TranscriptionQueueState(
      snapshot: TranscriptionQueueSnapshot(
        bootstrapState: const QueueBootstrapReady(),
        queued: const [],
        processing: processing,
        processingSupportsStreaming: supportsStreaming,
        processingProgress: progress,
      ),
    );
  }

  group('NoteBubble — transcribing branches', () {
    testWidgets(
      'streaming model + progress: shows progress bar + cancel button',
      (tester) async {
        final note = makeNote();
        await pumpNoteBubble(
          tester,
          note: note,
          queueState: stateFor(
            processing: 'n1',
            supportsStreaming: true,
            progress: const AsrTranscribeProgress(
              progress: 0.42,
              partialText: '',
              processedAudio: Duration(seconds: 4),
              totalAudio: Duration(seconds: 10),
            ),
          ),
          onCancel: () {},
        );

        expect(
          find.byKey(const Key('note-bubble-progress-bar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('note-bubble-cancel-button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'non-streaming model (Whisper): spinner shown, cancel button hidden',
      (tester) async {
        final note = makeNote();
        await pumpNoteBubble(
          tester,
          note: note,
          queueState: stateFor(
            processing: 'n1',
            supportsStreaming: false,
            progress: null,
          ),
          onCancel: () {},
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byKey(const Key('note-bubble-progress-bar')), findsNothing);
        expect(
          find.byKey(const Key('note-bubble-cancel-button')),
          findsNothing,
        );
      },
    );

    testWidgets('queued status: cancel button is shown for any model', (
      tester,
    ) async {
      final note = makeNote(status: TranscriptionStatus.queued);
      await pumpNoteBubble(
        tester,
        note: note,
        queueState: stateFor(),
        onCancel: () {},
      );

      // Queued path использует _StatusLine.action — рендерится TextButton.icon
      // с label noteActionCancel. Ключи не добавлены к legacy-статусам.
      expect(find.text('Отменить'), findsOneWidget);
    });
  });
}
