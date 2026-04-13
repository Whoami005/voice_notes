import 'package:equatable/equatable.dart';

/// Domain-представление аудиофайла, привязанного к заметке.
///
/// Все поля non-null: если сущность существует, то инвариант
/// «у заметки есть аудио» держится целиком. Nullable живёт только
/// на уровне `NoteEntity.audio`.
class NoteAudioEntity extends Equatable {
  /// Относительный путь к WAV-файлу относительно Documents-директории.
  /// Формат: 'audio/recordings/{noteUuid}.wav'.
  final String relativePath;

  /// Размер файла в байтах.
  final int sizeBytes;

  /// Частота дискретизации (Hz).
  final int sampleRate;

  /// Длительность аудио.
  final Duration duration;

  const NoteAudioEntity({
    required this.relativePath,
    required this.sizeBytes,
    required this.sampleRate,
    required this.duration,
  });

  NoteAudioEntity copyWith({
    String? relativePath,
    int? sizeBytes,
    int? sampleRate,
    Duration? duration,
  }) {
    return NoteAudioEntity(
      relativePath: relativePath ?? this.relativePath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sampleRate: sampleRate ?? this.sampleRate,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object> get props => [relativePath, sizeBytes, sampleRate, duration];
}
