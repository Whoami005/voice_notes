import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/theme/app_theme.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';
import 'package:voice_notes/feature/presentation/pages/settings/models/widgets/model_card/model_card.dart';
import 'package:voice_notes/l10n/app_localizations.dart';

void main() {
  Future<void> pumpModelCard(
    WidgetTester tester, {
    required AsrModelEntity model,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ru'),
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: ModelCard(model: model)),
        ),
      ),
    );
  }

  AsrModelEntity findStreaming() =>
      AsrModelEntity.availableModels.firstWhere((m) => m.supportsStreaming);

  AsrModelEntity findNonStreaming() =>
      AsrModelEntity.availableModels.firstWhere((m) => !m.supportsStreaming);

  group('ModelCard — capabilities + recommendations', () {
    testWidgets('streaming model: shows three capability '
        'chips + streaming recommendation', (tester) async {
      await pumpModelCard(tester, model: findStreaming());

      expect(
        find.byKey(const Key('model-card-capability-realtime')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('model-card-capability-cancelable')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('model-card-capability-partial-text')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('model-card-recommendation')),
        findsOneWidget,
      );
      expect(find.textContaining('любой длины'), findsOneWidget);
    });

    testWidgets(
      'non-streaming model: no capability chips, offline recommendation',
      (tester) async {
        await pumpModelCard(tester, model: findNonStreaming());

        expect(
          find.byKey(const Key('model-card-capability-realtime')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('model-card-capability-cancelable')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('model-card-capability-partial-text')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('model-card-recommendation')),
          findsOneWidget,
        );
        expect(find.textContaining('чанкинг'), findsOneWidget);
      },
    );
  });
}
