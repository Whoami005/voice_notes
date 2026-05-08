import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/error/app_exception.dart' as app_exc;
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/asr/asr_result.dart';
import 'package:voice_notes/core/packages/backup/app_data_backup_models.dart';
import 'package:voice_notes/core/packages/import/app_data_import_models.dart';
import 'package:voice_notes/core/packages/import/app_data_import_service.dart';
import 'package:voice_notes/core/packages/import/backup_file_picker_service.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_controller.dart';
import 'package:voice_notes/core/packages/transcription/transcription_queue_snapshot.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/general/screens/general_settings_screen.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late GetIt getIt;
  late SharedPreferences prefs;
  late RecordingPreferences recordingPreferences;
  late MockNoteRepository noteRepository;
  late _FakeBackupFilePickerService filePickerService;
  late _FakeAppDataImportService importService;
  late _FakeTranscriptionQueueController queueController;
  late Directory tempDir;
  late XFile backupFile;
  late XFile brokenBackupFile;

  setUp(() async {
    getIt = GetIt.instance;
    await getIt.reset();

    SharedPreferences.setMockInitialValues({
      ThemeCubit.prefsKey: 'dark',
      LocaleCubit.prefsKey: 'ru',
      'recording.keep_originals': true,
    });
    prefs = await SharedPreferences.getInstance();
    recordingPreferences = RecordingPreferences(prefs);

    noteRepository = MockNoteRepository();
    filePickerService = _FakeBackupFilePickerService();
    importService = _FakeAppDataImportService();
    queueController = _FakeTranscriptionQueueController();

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

    tempDir = await Directory.systemTemp.createTemp(
      'voice-notes-settings-import',
    );
    final file = File(p.join(tempDir.path, 'backup.zip'));
    await file.writeAsBytes(const [1, 2, 3], flush: true);
    backupFile = XFile(file.path);

    final brokenFile = File(p.join(tempDir.path, 'broken-backup.zip'));
    await brokenFile.writeAsBytes(const [4, 5, 6], flush: true);
    brokenBackupFile = XFile(brokenFile.path);

    filePickerService.result = backupFile;

    getIt
      ..registerSingleton<RecordingPreferences>(recordingPreferences)
      ..registerSingleton<NoteRepository>(noteRepository)
      ..registerSingleton<BackupFilePickerService>(filePickerService)
      ..registerSingleton<AppDataImportService>(importService)
      ..registerSingleton<TranscriptionQueueController>(queueController);
  });

  tearDown(() async {
    await getIt.reset();
    await queueController.dispose();

    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1200, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: AppRoutes.settings.general,
      routes: [
        GoRoute(
          path: AppRoutes.settings.general,
          builder: (context, state) =>
              const Scaffold(body: GeneralSettingsScreen()),
        ),
        GoRoute(
          path: AppRoutes.settings.queue,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('queue-screen', key: Key('queue-screen'))),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(prefs: prefs)),
          BlocProvider(create: (_) => LocaleCubit(prefs: prefs)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          theme: AppTheme.light,
        ),
      ),
    );
  }

  Future<void> openImportSheet(WidgetTester tester) async {
    await pumpScreen(tester);
    await tester.scrollUntilVisible(
      find.text('Импорт данных'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Импорт данных'));
    await tester.pumpAndSettle();
  }

  group('GeneralSettingsScreen import flow', () {
    testWidgets('opens import sheet and shows preview after picking file', (
      tester,
    ) async {
      importService.preview = _previewFor(fileName: backupFile.name);

      await openImportSheet(tester);

      expect(find.byKey(const Key('import-sheet-choose-file')), findsOneWidget);
      expect(find.byKey(const Key('import-sheet-submit')), findsOneWidget);
      expect(find.text('Предпросмотр резервной копии'), findsNothing);

      await tester.tap(find.byKey(const Key('import-sheet-choose-file')));
      await tester.pumpAndSettle();

      expect(importService.inspectedFiles, [backupFile.path]);
      expect(find.text('Предпросмотр резервной копии'), findsOneWidget);
      expect(find.text(backupFile.name), findsWidgets);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets(
      'disables import while queue is busy and navigates to queue screen',
      (tester) async {
        queueController.currentSnapshot = const TranscriptionQueueSnapshot(
          queued: ['queued-note'],
        );
        importService.preview = _previewFor(fileName: backupFile.name);

        await openImportSheet(tester);
        await tester.tap(find.byKey(const Key('import-sheet-choose-file')));
        await tester.pumpAndSettle();

        final submit = tester.widget<FilledButton>(
          find.byKey(const Key('import-sheet-submit')),
        );

        expect(
          find.byKey(const Key('import-sheet-open-queue')),
          findsOneWidget,
        );
        expect(find.textContaining('активных задач в очереди'), findsOneWidget);
        expect(submit.onPressed, isNull);

        await tester.tap(find.byKey(const Key('import-sheet-open-queue')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('queue-screen')), findsOneWidget);
      },
    );

    testWidgets(
      'shows success and warning toasts and closes sheet after import',
      (tester) async {
        final completer = Completer<AppDataImportResult>();
        importService
          ..preview = _previewFor(fileName: backupFile.name)
          ..importImpl = (_) => completer.future;

        await openImportSheet(tester);
        await tester.tap(find.byKey(const Key('import-sheet-choose-file')));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const Key('import-sheet-submit')),
          120,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.byKey(const Key('import-sheet-submit')));
        await tester.pumpAndSettle();

        expect(find.text('Импортировать резервную копию?'), findsOneWidget);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Импортировать'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        completer.complete(_successResult(withWarnings: true));
        await tester.pumpAndSettle();

        expect(find.text('Резервная копия импортирована'), findsOneWidget);
        expect(
          find.text('Импорт завершён с предупреждениями: 1'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('import-sheet-submit')), findsNothing);
        expect(prefs.getString(ThemeCubit.prefsKey), 'light');
        expect(prefs.getString(LocaleCubit.prefsKey), 'en');
        expect(recordingPreferences.keepOriginals, isFalse);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'clears stale preview when inspecting a new backup fails',
      (tester) async {
        importService
          ..preview = _previewFor(fileName: backupFile.name)
          ..inspectImpl = (file) async {
            if (file.path == brokenBackupFile.path) {
              throw const app_exc.FormatException.json('broken backup');
            }

            return _previewFor(fileName: file.name);
          };

        await openImportSheet(tester);

        await tester.tap(find.byKey(const Key('import-sheet-choose-file')));
        await tester.pumpAndSettle();

        expect(find.text('Предпросмотр резервной копии'), findsOneWidget);
        expect(find.text(backupFile.name), findsWidgets);

        filePickerService.result = brokenBackupFile;

        await tester.tap(find.byKey(const Key('import-sheet-choose-file')));
        await tester.pumpAndSettle();

        final submit = tester.widget<FilledButton>(
          find.byKey(const Key('import-sheet-submit')),
        );

        expect(find.text('Предпросмотр резервной копии'), findsNothing);
        expect(find.text(backupFile.name), findsNothing);
        expect(find.textContaining('Ошибка обработки данных'), findsOneWidget);
        expect(submit.onPressed, isNull);
        expect(importService.importedFiles, isEmpty);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'shows error toast and keeps import sheet open when import fails',
      (tester) async {
        importService
          ..preview = _previewFor(fileName: backupFile.name)
          ..importImpl = (_) async => throw StateError('boom');

        await openImportSheet(tester);
        await tester.tap(find.byKey(const Key('import-sheet-choose-file')));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byKey(const Key('import-sheet-submit')),
          120,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.byKey(const Key('import-sheet-submit')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ElevatedButton, 'Импортировать'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('import-sheet-submit')), findsOneWidget);
        expect(find.text('Bad state: boom'), findsOneWidget);

        await tester.pump(const Duration(seconds: 5));
      },
    );
  });
}

AppDataImportPreview _previewFor({required String fileName}) {
  return AppDataImportPreview(
    fileName: fileName,
    manifest: const AppDataBackupManifest(
      schemaVersion: 1,
      app: 'voice_notes',
      exportedAt: '2026-05-08T12:30:45.000Z',
      includesAudio: true,
      counts: AppDataBackupCounts(folders: 1, tags: 1, notes: 2, audioFiles: 1),
    ),
    warningsCount: 0,
  );
}

AppDataImportResult _successResult({bool withWarnings = false}) {
  return AppDataImportResult(
    backup: const AppDataBackupPayload(
      settings: AppDataBackupSettings(
        themeMode: 'light',
        localeCode: 'en',
        recording: AppDataBackupRecordingSettings(keepOriginals: false),
        selectedModelId: null,
      ),
      folders: [],
      tags: [],
      notes: [],
    ),
    warnings: withWarnings
        ? const [MissingAudioImportWarning(count: 1)]
        : const [],
    restoredFoldersCount: 1,
    restoredTagsCount: 1,
    restoredNotesCount: 2,
    restoredAudioCount: 1,
  );
}

class _FakeBackupFilePickerService implements BackupFilePickerService {
  XFile? result;

  @override
  Future<XFile?> pickBackupFile() async => result;
}

class _FakeAppDataImportService implements AppDataImportService {
  AppDataImportPreview preview = _previewFor(fileName: 'backup.zip');
  Future<AppDataImportPreview> Function(XFile file)? inspectImpl;
  Future<AppDataImportResult> Function(XFile file)? importImpl;

  final List<String> inspectedFiles = [];
  final List<String> importedFiles = [];

  @override
  Future<AppDataImportPreview> inspectBackup(XFile file) async {
    inspectedFiles.add(file.path);
    final handler = inspectImpl;
    if (handler != null) return handler(file);

    return preview;
  }

  @override
  Future<AppDataImportResult> importBackup({required XFile file}) async {
    importedFiles.add(file.path);
    final handler = importImpl;
    if (handler != null) return handler(file);

    return _successResult();
  }
}

class _FakeTranscriptionQueueController
    implements TranscriptionQueueController {
  final StreamController<TranscriptionQueueSnapshot> _snapshotController =
      StreamController<TranscriptionQueueSnapshot>.broadcast();

  TranscriptionQueueSnapshot currentSnapshot =
      const TranscriptionQueueSnapshot();

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
  }) async {
    return const AsrResult(text: 'ok');
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
