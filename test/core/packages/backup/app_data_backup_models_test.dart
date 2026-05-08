import 'package:flutter_test/flutter_test.dart';
import 'package:voice_notes/core/packages/backup/app_data_backup_models.dart';

void main() {
  group('AppDataBackupPayload.fromJson', () {
    test('throws FormatException when settings is not a JSON object', () {
      final json = _validPayloadJson()..['settings'] = 'invalid';

      expect(
        () => AppDataBackupPayload.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains("'settings'"),
          ),
        ),
      );
    });

    test('throws FormatException when tags contain a non-object item', () {
      final json = _validPayloadJson()..['tags'] = ['invalid'];

      expect(
        () => AppDataBackupPayload.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains("'tags[0]'"),
          ),
        ),
      );
    });
  });

  group('AppDataBackupTranscriptionSegment.fromJson', () {
    test('throws FormatException when index is not an integer', () {
      final json = _validSegmentJson()..['index'] = '0';

      expect(
        () => AppDataBackupTranscriptionSegment.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains("'index'"),
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _validPayloadJson() => {
  'settings': {
    'themeMode': 'light',
    'localeCode': 'en',
    'recording': {'keepOriginals': false},
    'selectedModelId': 'streaming-zipformer-en-2023-06-26',
  },
  'folders': const <Map<String, Object?>>[],
  'tags': const <Map<String, Object?>>[],
  'notes': const <Map<String, Object?>>[],
};

Map<String, dynamic> _validSegmentJson() => {
  'index': 0,
  'text': 'Segment',
  'startMs': 0,
  'endMs': 1200,
  'languageCode': 'en',
  'tokens': const ['Segment'],
  'tokenTimestampsMs': const [0],
};
