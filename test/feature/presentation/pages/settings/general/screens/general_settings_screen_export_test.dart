import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/export/app_data_export_models.dart';
import 'package:voice_notes/core/packages/export/app_data_export_service.dart';
import 'package:voice_notes/core/packages/export/app_data_share_service.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/enums/share_result_status_enum.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/screens/general_settings_screen.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

class MockRecordingPreferences extends Mock implements RecordingPreferences {}

class MockAppDataExportService extends Mock implements AppDataExportService {}

class MockAppDataShareService extends Mock implements AppDataShareService {}

class FakeThemeState extends Fake implements ThemeState {}

class FakeLocaleState extends Fake implements LocaleState {}

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  late GetIt getIt;
  late MockNoteRepository noteRepository;
  late MockRecordingPreferences recordingPreferences;
  late MockAppDataExportService exportService;
  late MockAppDataShareService shareService;
  late SharedPreferences prefs;

  setUpAll(() {
    registerFallbackValue(FakeThemeState());
    registerFallbackValue(FakeLocaleState());
    registerFallbackValue(FakeBuildContext());
  });

  setUp(() async {
    getIt = GetIt.instance;
    await getIt.reset();

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    noteRepository = MockNoteRepository();
    recordingPreferences = MockRecordingPreferences();
    exportService = MockAppDataExportService();
    shareService = MockAppDataShareService();

    when(() => recordingPreferences.keepOriginals).thenReturn(true);
    when(
      () => noteRepository.watchQueued(),
    ).thenAnswer((_) => Stream.value(const <NoteEntity>[]));
    when(
      () => noteRepository.watchTranscribing(),
    ).thenAnswer((_) => Stream.value(const <NoteEntity>[]));
    when(
      () => noteRepository.watchFailed(),
    ).thenAnswer((_) => Stream.value(const <NoteEntity>[]));
    when(
      () => noteRepository.watchCancelled(),
    ).thenAnswer((_) => Stream.value(const <NoteEntity>[]));

    when(() => exportService.getSummary()).thenAnswer(
      (_) async => const AppDataExportSummary(
        notesCount: 2,
        audioCount: 1,
        audioBytes: 2048,
      ),
    );

    getIt
      ..registerSingleton<RecordingPreferences>(recordingPreferences)
      ..registerSingleton<NoteRepository>(noteRepository)
      ..registerSingleton<AppDataExportService>(exportService)
      ..registerSingleton<AppDataShareService>(shareService);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(prefs: prefs)),
          BlocProvider(create: (_) => LocaleCubit(prefs: prefs)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          theme: AppTheme.light,
          home: const Scaffold(body: GeneralSettingsScreen()),
        ),
      ),
    );
  }

  group('GeneralSettingsScreen export flow', () {
    testWidgets(
      'shows success toast and closes export sheet when sharing succeeds',
      (tester) async {
        final completer = Completer<ExportArtifact>();
        final artifact = ExportArtifact(
          file: File('/tmp/voice-notes-backup.zip'),
          fileName: 'voice-notes-backup-20260508-123045.zip',
          exportedAt: DateTime.utc(2026, 5, 8, 12, 30, 45),
          includesAudio: true,
        );

        when(
          () => exportService.createBackup(
            options: const AppDataExportOptions(includeAudio: true),
          ),
        ).thenAnswer((_) => completer.future);
        when(
          () => shareService.shareBackup(
            context: any(named: 'context'),
            artifact: artifact,
          ),
        ).thenAnswer((_) async => ShareResultStatusEnum.success);

        await pumpScreen(tester);
        await tester.scrollUntilVisible(
          find.text('Экспорт данных'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Экспорт данных'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('export-sheet-include-audio')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('export-sheet-create')), findsOneWidget);

        await tester.tap(find.byKey(const Key('export-sheet-include-audio')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('export-sheet-create')));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        verify(() => exportService.getSummary()).called(1);
        verify(
          () => exportService.createBackup(
            options: const AppDataExportOptions(includeAudio: true),
          ),
        ).called(1);

        completer.complete(artifact);
        await tester.pumpAndSettle();

        verify(
          () => shareService.shareBackup(
            context: any(named: 'context'),
            artifact: artifact,
          ),
        ).called(1);

        expect(find.text('Резервная копия готова'), findsOneWidget);
        expect(
          find.byKey(const Key('export-sheet-include-audio')),
          findsNothing,
        );
        expect(find.byKey(const Key('export-sheet-create')), findsNothing);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '''keeps export sheet open and shows no toast when share sheet is dismissed''',
      (tester) async {
        final completer = Completer<ExportArtifact>();
        final artifact = ExportArtifact(
          file: File('/tmp/voice-notes-backup.zip'),
          fileName: 'voice-notes-backup-20260508-123045.zip',
          exportedAt: DateTime.utc(2026, 5, 8, 12, 30, 45),
          includesAudio: true,
        );

        when(
          () => exportService.createBackup(
            options: const AppDataExportOptions(includeAudio: true),
          ),
        ).thenAnswer((_) => completer.future);
        when(
          () => shareService.shareBackup(
            context: any(named: 'context'),
            artifact: artifact,
          ),
        ).thenAnswer((_) async => ShareResultStatusEnum.dismissed);

        await pumpScreen(tester);
        await tester.scrollUntilVisible(
          find.text('Экспорт данных'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Экспорт данных'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('export-sheet-include-audio')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('export-sheet-create')), findsOneWidget);

        await tester.tap(find.byKey(const Key('export-sheet-include-audio')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('export-sheet-create')));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete(artifact);
        await tester.pumpAndSettle();

        verify(
          () => shareService.shareBackup(
            context: any(named: 'context'),
            artifact: artifact,
          ),
        ).called(1);

        expect(
          find.byKey(const Key('export-sheet-include-audio')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('export-sheet-create')), findsOneWidget);

        expect(find.text('Резервная копия готова'), findsNothing);
        expect(
          find.text('Произошла непредвиденная ошибка. Попробуйте ещё раз'),
          findsNothing,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      '''shows error toast and keeps export sheet open when sharing is unavailable''',
      (tester) async {
        final completer = Completer<ExportArtifact>();
        final artifact = ExportArtifact(
          file: File('/tmp/voice-notes-backup.zip'),
          fileName: 'voice-notes-backup-20260508-123045.zip',
          exportedAt: DateTime.utc(2026, 5, 8, 12, 30, 45),
          includesAudio: true,
        );

        when(
          () => exportService.createBackup(
            options: const AppDataExportOptions(includeAudio: true),
          ),
        ).thenAnswer((_) => completer.future);
        when(
          () => shareService.shareBackup(
            context: any(named: 'context'),
            artifact: artifact,
          ),
        ).thenAnswer((_) async => ShareResultStatusEnum.unavailable);

        await pumpScreen(tester);
        await tester.scrollUntilVisible(
          find.text('Экспорт данных'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Экспорт данных'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('export-sheet-include-audio')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('export-sheet-create')), findsOneWidget);

        await tester.tap(find.byKey(const Key('export-sheet-include-audio')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('export-sheet-create')));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete(artifact);
        await tester.pumpAndSettle();

        verify(
          () => shareService.shareBackup(
            context: any(named: 'context'),
            artifact: artifact,
          ),
        ).called(1);

        expect(
          find.byKey(const Key('export-sheet-include-audio')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('export-sheet-create')), findsOneWidget);

        expect(find.text('Резервная копия готова'), findsNothing);
        expect(
          find.text('Произошла непредвиденная ошибка. Попробуйте ещё раз'),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pump(const Duration(seconds: 5));
      },
    );
  });
}
