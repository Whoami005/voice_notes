import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/player/audio_player_service.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/presentation/widgets/audio/audio_play_button.dart';

void main() {
  testWidgets('shows play icon for init status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AudioPlayButton(status: PlaybackStatus.init),
        ),
      ),
    );

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
  });
}
