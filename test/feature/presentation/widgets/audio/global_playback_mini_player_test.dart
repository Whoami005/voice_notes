import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:voice_notes/core/packages/app_router/routes/app_routes.dart';
import 'package:voice_notes/core/packages/player/audio_playback_controller.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/presentation/widgets/audio/global_playback_mini_player.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

void main() {
  late _FakeAudioPlaybackController controller;

  setUp(() {
    controller = _FakeAudioPlaybackController();
  });

  tearDown(() async {
    await controller.dispose();
  });

  Future<void> pumpMiniPlayer(WidgetTester tester) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: GlobalPlaybackMiniPlayer(
              controller: controller,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.folders.noteDetail(
            folderId: 'folder',
            noteId: 'note',
          ),
          builder: (context, state) =>
              const Scaffold(body: Text('note-detail')),
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

  testWidgets('shows current session title and pauses playback', (
    tester,
  ) async {
    await pumpMiniPlayer(tester);

    controller.pushSession(
      const PlaybackSessionState(
        trackId: 'note',
        title: 'Текущая заметка',
        folderId: 'folder',
        status: PlaybackStatus.playing,
        position: Duration(seconds: 2),
        duration: Duration(seconds: 10),
      ),
    );
    await tester.pump();

    expect(find.text('Текущая заметка'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();

    expect(controller.pauseCalls, 1);
  });

  testWidgets('opens current note when player tile is tapped', (tester) async {
    await pumpMiniPlayer(tester);

    controller.pushSession(
      const PlaybackSessionState(
        trackId: 'note',
        title: 'Текущая заметка',
        folderId: 'folder',
        status: PlaybackStatus.playing,
        position: Duration(seconds: 2),
        duration: Duration(seconds: 10),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Текущая заметка'));
    await tester.pumpAndSettle();

    expect(find.text('note-detail'), findsOneWidget);
  });
}

class _FakeAudioPlaybackController implements AudioPlaybackController {
  final StreamController<PlaybackSessionState> _sessionController =
      StreamController<PlaybackSessionState>.broadcast();

  PlaybackSessionState _session = const PlaybackSessionState.hidden();
  int pauseCalls = 0;

  void pushSession(PlaybackSessionState session) {
    _session = session;
    _sessionController.add(session);
  }

  @override
  PlaybackSessionState get session => _session;

  @override
  Stream<PlaybackSessionState> get sessionStream => _sessionController.stream;

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> dispose() async {
    await _sessionController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
