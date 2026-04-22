import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/asr/asr_cubit.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/state/status/status_state.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/domain/enums/queue_runtime_reason.dart';
import 'package:voice_notes/feature/presentation/pages/queue/logic/transcription_queue_cubit.dart';
import 'package:voice_notes/feature/presentation/widgets/asr_status_banner.dart';
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

    when(
      () => asrCubit.state,
    ).thenReturn(const AsrState(status: Status.success, hasModel: true));
    when(() => queueCubit.resumeAfterInterruptedRun()).thenAnswer((_) async {});
  });

  Future<void> pumpBanner(
    WidgetTester tester, {
    required TranscriptionQueueState queueState,
  }) {
    when(() => queueCubit.state).thenReturn(queueState);
    whenListen(queueCubit, Stream.value(queueState), initialState: queueState);
    whenListen(
      asrCubit,
      Stream.value(const AsrState(status: Status.success, hasModel: true)),
      initialState: const AsrState(status: Status.success, hasModel: true),
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return Scaffold(
              body: MultiBlocProvider(
                providers: [
                  BlocProvider<TranscriptionQueueCubit>.value(
                    value: queueCubit,
                  ),
                  BlocProvider<AsrCubit>.value(value: asrCubit),
                ],
                child: const AsrStatusBanner(),
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.settings.queue,
          builder: (context, state) =>
              const Scaffold(body: Text('queue-screen')),
        ),
      ],
    );

    return tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }

  TranscriptionQueueState interruptedState() {
    return const TranscriptionQueueState(
      snapshot: TranscriptionQueueSnapshot(
        bootstrapState: QueueBootstrapReady(),
        runtimeReason: QueueRuntimeReason.interruptedPreviousRun,
      ),
    );
  }

  group('AsrStatusBanner', () {
    testWidgets('shows interrupted queue banner and resumes queue on tap', (
      tester,
    ) async {
      await pumpBanner(tester, queueState: interruptedState());

      expect(find.text('Предыдущая расшифровка была прервана'), findsOneWidget);

      await tester.tap(find.text('Предыдущая расшифровка была прервана'));
      await tester.pump();

      verify(() => queueCubit.resumeAfterInterruptedRun()).called(1);
    });

    testWidgets('opens queue screen from trailing action', (tester) async {
      await pumpBanner(tester, queueState: interruptedState());

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('queue-screen'), findsOneWidget);
    });
  });
}
