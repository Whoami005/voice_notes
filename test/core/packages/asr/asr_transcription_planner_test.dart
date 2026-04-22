import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_planner.dart';
import 'package:voice_notes/core/packages/asr/asr_transcription_strategy.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

void main() {
  AsrModelEntity modelById(AsrModelIdEnum id) {
    return AsrModelEntity.availableModels.firstWhere(
      (model) => model.uuid == id,
    );
  }

  group('AsrTranscriptionPlanner', () {
    test('streaming model always resolves to streaming strategy', () {
      final plan = AsrTranscriptionPlanner.resolve(
        model: modelById(AsrModelIdEnum.streamingZipformerEn),
        audioDuration: const Duration(hours: 1),
      );

      expect(plan.strategy, AsrTranscriptionStrategy.streaming);
      expect(plan.supportsInteractiveProgress, isTrue);
      expect(plan.supportsCancellation, isTrue);
    });

    test('whisper tiny short audio resolves to singlePass', () {
      final plan = AsrTranscriptionPlanner.resolve(
        model: modelById(AsrModelIdEnum.whisperTinyEn),
        audioDuration: const Duration(minutes: 2),
      );

      expect(plan.strategy, AsrTranscriptionStrategy.singlePass);
      expect(plan.supportsInteractiveProgress, isFalse);
      expect(plan.supportsCancellation, isFalse);
    });

    test('whisper tiny longer audio resolves to chunked', () {
      final plan = AsrTranscriptionPlanner.resolve(
        model: modelById(AsrModelIdEnum.whisperTinyEn),
        audioDuration: const Duration(minutes: 3),
      );

      expect(plan.strategy, AsrTranscriptionStrategy.chunked);
      expect(plan.supportsInteractiveProgress, isTrue);
      expect(plan.supportsCancellation, isTrue);
    });

    test('whisper small medium audio resolves to chunked', () {
      final plan = AsrTranscriptionPlanner.resolve(
        model: modelById(AsrModelIdEnum.whisperSmall),
        audioDuration: const Duration(minutes: 4),
      );

      expect(plan.strategy, AsrTranscriptionStrategy.chunked);
      expect(plan.supportsInteractiveProgress, isTrue);
      expect(plan.supportsCancellation, isTrue);
    });

    test('whisper small after 5 minutes resolves to chunkedVad', () {
      final plan = AsrTranscriptionPlanner.resolve(
        model: modelById(AsrModelIdEnum.whisperSmall),
        audioDuration: const Duration(minutes: 6),
        vadModelPath: '/tmp/silero_vad.onnx',
      );

      expect(plan.strategy, AsrTranscriptionStrategy.chunkedVad);
      expect(plan.vadConfig?.modelPath, '/tmp/silero_vad.onnx');
    });

    test(
      'whisper medium long audio resolves to chunkedVad when model exists',
      () {
        final plan = AsrTranscriptionPlanner.resolve(
          model: modelById(AsrModelIdEnum.whisperMedium),
          audioDuration: const Duration(minutes: 40),
          vadModelPath: '/tmp/silero_vad.onnx',
        );

        expect(plan.strategy, AsrTranscriptionStrategy.chunkedVad);
        expect(plan.vadConfig?.modelPath, '/tmp/silero_vad.onnx');
      },
    );

    test('chunkedVad override degrades to chunked without vad model path', () {
      final plan = AsrTranscriptionPlanner.resolve(
        model: modelById(AsrModelIdEnum.whisperMedium),
        audioDuration: const Duration(minutes: 40),
        strategyOverride: AsrTranscriptionStrategy.chunkedVad,
      );

      expect(plan.strategy, AsrTranscriptionStrategy.chunked);
      expect(plan.vadConfig, isNull);
    });

    test('unknown duration prefers chunked for cancel-friendly UX', () {
      final plan = AsrTranscriptionPlanner.resolve(
        model: modelById(AsrModelIdEnum.whisperSmall),
        audioDuration: Duration.zero,
      );

      expect(plan.strategy, AsrTranscriptionStrategy.chunked);
      expect(plan.supportsInteractiveProgress, isTrue);
      expect(plan.supportsCancellation, isTrue);
    });
  });
}
