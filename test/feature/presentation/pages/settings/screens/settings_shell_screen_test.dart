import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_notes/core/l10n/locale_cubit.dart';
import 'package:voice_notes/core/packages/app_router/route_builder.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_route_names.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/downloader/download_manager.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/core/theme/theme_cubit.dart';
import 'package:voice_notes/feature/data/local/preferences/recording_preferences.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';
import 'package:voice_notes/feature/domain/repositories/model_repository.dart';
import 'package:voice_notes/feature/domain/repositories/note_repository.dart';
import 'package:voice_notes/feature/presentation/pages/settings/components/settings_workspace_right_pane.dart';
import 'package:voice_notes/feature/presentation/pages/settings/screens/settings_shell_screen.dart';
import 'package:voice_notes/feature/presentation/widgets/base_pop_scope.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

class _MockModelRepository extends Mock implements ModelRepository {}

class _MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late _MockModelRepository modelRepository;
  late _MockNoteRepository noteRepository;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      ThemeCubit.prefsKey: AppThemeMode.dark.name,
      LocaleCubit.prefsKey: 'ru',
      'recording.keep_originals': true,
    });
    prefs = await SharedPreferences.getInstance();
    modelRepository = _MockModelRepository();
    noteRepository = _MockNoteRepository();

    when(
      () => modelRepository.verifyAllModels(),
    ).thenAnswer((_) async => Future<void>.value());
    when(
      () => modelRepository.getModelsWithStatus(),
    ).thenAnswer((_) async => const []);
    when(
      () => modelRepository.watchAllDownloads(),
    ).thenAnswer((_) => const Stream<ModelDownloadProgress>.empty());

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

    await getIt.reset();
    getIt
      ..registerSingleton<RecordingPreferences>(RecordingPreferences(prefs))
      ..registerSingleton<ModelRepository>(modelRepository)
      ..registerSingleton<NoteRepository>(noteRepository);
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('SettingsWorkspaceRightPane', () {
    testWidgets(
      'shows models for /settings/general without blocking pop at pane level',
      (tester) async {
        await _pumpWorkspaceRightPane(
          tester,
          initialLocation: '/settings/general',
        );

        expect(find.text('models-pane'), findsOneWidget);
        expect(find.text('general-pane'), findsNothing);
        expect(find.byType(BasePopScope), findsNothing);
      },
    );

    testWidgets('shows general branch child for nested storage detail routes', (
      tester,
    ) async {
      await _pumpWorkspaceRightPane(
        tester,
        initialLocation: '/settings/general/storage/folder-1',
      );

      expect(find.text('general-pane'), findsOneWidget);
      expect(find.text('models-pane'), findsNothing);
    });
  });

  group('SettingsShellScreen workspace routing', () {
    testWidgets(
      'keeps /settings/general stable on workspace instead of mutating to models',
      (tester) async {
        tester.view
          ..physicalSize = const Size(1400, 1200)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = _buildSettingsWorkspaceRouter();

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => ThemeCubit(prefs: prefs)),
              BlocProvider(create: (_) => LocaleCubit(prefs: prefs)),
            ],
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1200, 900)),
              child: MaterialApp.router(
                routerConfig: router,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                locale: const Locale('ru'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          router.routeInformationProvider.value.uri.path,
          '/settings/general',
        );
        expect(find.text('models-shell-child'), findsOneWidget);
      },
    );
  });
}

Future<void> _pumpWorkspaceRightPane(
  WidgetTester tester, {
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        name: AppRouteNames.settings.general,
        path: '/settings/general',
        builder: (context, state) => const SettingsWorkspaceRightPane(
          children: [Text('general-pane'), Text('models-pane')],
        ),
      ),
      GoRoute(
        name: AppRouteNames.settings.storageDetail,
        path: '/settings/general/storage/folder-1',
        builder: (context, state) => const SettingsWorkspaceRightPane(
          children: [Text('general-pane'), Text('models-pane')],
        ),
      ),
    ],
  );

  return tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(1200, 900)),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

GoRouter _buildSettingsWorkspaceRouter() {
  return GoRouter(
    initialLocation: '/settings/general',
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) =>
            Scaffold(
              body: wrapRoute(
                context,
                SettingsShellScreen(
                  navigationShell: navigationShell,
                  children: children,
                ),
              ),
            ),
        branches: [
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                name: AppRouteNames.settings.general,
                path: '/settings/general',
                builder: (context, state) => const Text('general-shell-child'),
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: [
              GoRoute(
                name: AppRouteNames.settings.models,
                path: '/settings/models',
                builder: (context, state) => const Text('models-shell-child'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
