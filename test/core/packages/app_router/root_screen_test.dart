import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/root_screen.dart';
import 'package:voice_notes/core/packages/di/injection.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_bottom_nav.dart';
import 'package:voice_notes/feature/presentation/widgets/bottom_navigation_bar/app_navigation_rail.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

void main() {
  late _FakeAudioPlaybackController controller;

  setUp(() {
    controller = _FakeAudioPlaybackController();
    getIt.registerSingleton<AudioPlaybackController>(controller);
  });

  tearDown(() async {
    if (GetIt.I.isRegistered<AudioPlaybackController>()) {
      await getIt.unregister<AudioPlaybackController>();
    }

    await controller.dispose();
  });

  testWidgets('shows bottom nav on compact width', (tester) async {
    await _pumpRootScreen(tester, width: 600);

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(AppNavigationRail), findsNothing);
  });

  testWidgets('shows navigation rail on medium width', (tester) async {
    await _pumpRootScreen(tester, width: 700);

    expect(find.byType(AppBottomNav), findsNothing);
    expect(find.byType(AppNavigationRail), findsOneWidget);
  });

  testWidgets('tapping rail destination switches branch', (tester) async {
    await _pumpRootScreen(tester, width: 700);

    expect(find.text('folders-branch'), findsOneWidget);

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();

    expect(find.text('settings-branch'), findsOneWidget);
    expect(find.text('folders-branch'), findsNothing);
  });
}

Future<void> _pumpRootScreen(WidgetTester tester, {required double width}) {
  final router = GoRouter(
    initialLocation: '/folders',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/folders',
                builder: (context, state) =>
                    const Scaffold(body: Text('folders-branch')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings/general',
                builder: (context, state) =>
                    const Scaffold(body: Text('settings-branch')),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
}

class _FakeAudioPlaybackController implements AudioPlaybackController {
  final StreamController<PlaybackSessionState> _sessionController =
      StreamController<PlaybackSessionState>.broadcast();

  @override
  PlaybackSessionState get session => const PlaybackSessionState.hidden();

  @override
  Stream<PlaybackSessionState> get sessionStream => _sessionController.stream;

  @override
  Future<void> clearSession() async {}

  @override
  Future<void> dispose() async {
    await _sessionController.close();
  }

  @override
  Future<List<double>?> getWaveform(String trackId) async => null;

  @override
  Future<void> pause() async {}

  @override
  Future<void> play(String trackId) async {}

  @override
  void register(String trackId, CachedTrackState state) {}

  @override
  Future<void> seek(String trackId, Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Stream<TrackState> trackStateStream(String trackId) => const Stream.empty();

  @override
  Future<void> togglePlayPause(String trackId) async {}
}
