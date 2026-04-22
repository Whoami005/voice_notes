import 'dart:io';
import 'dart:typed_data';

abstract final class AsrWavDurationReader {
  static Future<Duration?> readDuration(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    final raf = await file.open();
    final bytes = await raf.read(4096);
    await raf.close();
    if (bytes.length < 44) return null;

    final data = ByteData.sublistView(bytes);
    if (_readAscii(bytes, 0, 4) != 'RIFF' ||
        _readAscii(bytes, 8, 4) != 'WAVE') {
      return null;
    }

    int? byteRate;
    int? dataLength;

    int offset = 12;
    while (offset + 8 <= bytes.length) {
      final chunkId = _readAscii(bytes, offset, 4);
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;

      if (chunkId == 'fmt ' &&
          chunkSize >= 12 &&
          chunkDataOffset + 12 <= bytes.length) {
        byteRate = data.getUint32(chunkDataOffset + 8, Endian.little);
      }

      if (chunkId == 'data') {
        dataLength = chunkSize;
        break;
      }

      offset = chunkDataOffset + chunkSize + (chunkSize.isOdd ? 1 : 0);
    }

    if (byteRate == null || dataLength == null || byteRate <= 0) return null;

    final seconds = dataLength / byteRate;
    return Duration(
      microseconds: (seconds * Duration.microsecondsPerSecond).round(),
    );
  }

  static String _readAscii(Uint8List bytes, int offset, int length) {
    return String.fromCharCodes(bytes.sublist(offset, offset + length));
  }
}
