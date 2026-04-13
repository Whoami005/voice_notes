import 'package:objectbox/objectbox.dart';

/// Метаданные аудиофайла, привязанного к заметке.
///
/// Связан с `NoteObject` через `ToOne<NoteAudioObject>`. Если relation пустой
/// — у заметки нет сохранённого оригинала (настройка выключена, либо заметка
/// создана до Plan 1). Все поля внутри non-null: если сущность есть, то все
/// её поля гарантированно присутствуют.
@Entity()
class NoteAudioObject {
  @Id()
  int id;

  /// Денормализация из NoteObject для быстрых per-folder агрегаций
  /// в Storage screen. Nullable, потому что заметка может
  /// существовать без папки. Обновляется при перемещении заметки между
  /// папками в той же транзакции.
  @Index()
  String? folderUid;

  /// Относительный путь к WAV-файлу относительно Documents-директории:
  /// `audio/recordings/{noteUuid}.wav`. Резолвится через
  /// `AudioPaths.resolveRelativePath`.
  @Unique()
  String relativePath;

  /// Размер файла в байтах. Записывается при сохранении записи через
  /// File.lengthSync(). Используется для агрегаций в Storage screen
  /// без чтения файлов с диска.
  int sizeBytes;

  /// Частота дискретизации (Hz). Сейчас всегда 16000 (конфиг record).
  /// Храним явно для будущей совместимости с TTS-моделями (Plan 2),
  /// которые могут иметь 22050/24000 Hz.
  int sampleRate;

  /// Длительность аудио в миллисекундах.
  int durationMs;

  NoteAudioObject({
    required this.relativePath,
    required this.sizeBytes,
    required this.sampleRate,
    required this.durationMs,
    this.folderUid,
    this.id = 0,
  });
}
