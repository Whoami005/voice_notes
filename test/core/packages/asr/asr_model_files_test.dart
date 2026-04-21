import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/asr/asr_model_files.dart';
import 'package:voice_notes/feature/domain/entities/asr_model_entity.dart';

void main() {
  group('AsrModelEntity.getModelFiles', () {
    test('whisper → WhisperModelFiles с derived-именами из modelDirName', () {
      const model = AsrModelEntity(
        uuid: AsrModelIdEnum.whisperTinyEn,
        name: 'Whisper Tiny',
        engine: 'OpenAI Whisper',
        size: '117 MB',
        supportedLanguages: ['English'],
        modelDirName: 'sherpa-onnx-whisper-tiny.en',
        modelType: AsrModelType.whisper,
      );

      final files = model.getModelFiles();

      expect(files, isA<WhisperModelFiles>());
      final whisperFiles = files as WhisperModelFiles;
      expect(whisperFiles.encoder, 'tiny.en-encoder.int8.onnx');
      expect(whisperFiles.decoder, 'tiny.en-decoder.int8.onnx');
      expect(whisperFiles.tokens, 'tiny.en-tokens.txt');
      expect(
        whisperFiles.allFileNames,
        equals([
          'tiny.en-encoder.int8.onnx',
          'tiny.en-decoder.int8.onnx',
          'tiny.en-tokens.txt',
        ]),
      );
    });

    test('offlineTransducer → TransducerModelFiles с дефолтными именами', () {
      const model = AsrModelEntity(
        uuid: AsrModelIdEnum.parakeetTdtV3,
        name: 'Parakeet V3',
        engine: 'NVIDIA NeMo',
        size: '640 MB',
        supportedLanguages: ['English'],
        modelDirName: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8',
        modelType: AsrModelType.offlineTransducer,
        sherpaModelType: 'nemo_transducer',
      );

      final files = model.getModelFiles();

      expect(files, isA<TransducerModelFiles>());
      final transducerFiles = files as TransducerModelFiles;
      expect(transducerFiles.encoder, 'encoder.int8.onnx');
      expect(transducerFiles.decoder, 'decoder.int8.onnx');
      expect(transducerFiles.joiner, 'joiner.int8.onnx');
      expect(transducerFiles.tokens, 'tokens.txt');
    });

    test('streamingTransducer → TransducerModelFiles (тот же формат)', () {
      const model = AsrModelEntity(
        uuid: AsrModelIdEnum.streamingZipformerEn20M,
        name: 'Zipformer 20M',
        engine: 'k2-fsa',
        size: '44 MB',
        supportedLanguages: ['English'],
        modelDirName: 'sherpa-onnx-streaming-zipformer-en-20M-2023-02-17',
        modelType: AsrModelType.streamingTransducer,
      );

      final files = model.getModelFiles();

      expect(files, isA<TransducerModelFiles>());
    });

    test('customFiles overrides defaults', () {
      const custom = TransducerModelFiles(
        encoder: 'custom-encoder.onnx',
        decoder: 'custom-decoder.onnx',
        joiner: 'custom-joiner.onnx',
        tokens: 'custom-tokens.txt',
      );

      const model = AsrModelEntity(
        uuid: AsrModelIdEnum.streamingZipformerEn,
        name: 'Zipformer custom',
        engine: 'k2-fsa',
        size: '85 MB',
        supportedLanguages: ['English'],
        modelDirName: 'sherpa-onnx-streaming-zipformer-en-2023-06-26',
        modelType: AsrModelType.streamingTransducer,
        customFiles: custom,
      );

      expect(model.getModelFiles(), same(custom));
    });

    test('allFileNames включает все компоненты bundle-файлов', () {
      const whisperFiles = WhisperModelFiles(
        encoder: 'e.onnx',
        decoder: 'd.onnx',
        tokens: 't.txt',
      );
      expect(whisperFiles.allFileNames, hasLength(3));

      const transducerFiles = TransducerModelFiles(
        encoder: 'e.onnx',
        decoder: 'd.onnx',
        joiner: 'j.onnx',
        tokens: 't.txt',
      );
      expect(transducerFiles.allFileNames, hasLength(4));
    });
  });

  group('AsrModelEntity.supportsStreaming', () {
    test('только streamingTransducer возвращает true', () {
      expect(
        AsrModelEntity.availableModels
            .where((m) => m.supportsStreaming)
            .map((m) => m.modelType)
            .toSet(),
        equals({AsrModelType.streamingTransducer}),
      );
    });
  });
}
