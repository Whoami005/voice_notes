import 'package:equatable/equatable.dart';
import 'package:voice_notes/feature/domain/entities/note_entity.dart';

/// Карточка «одна запись + её аудио» для списка в `FolderStorageScreen`.
class NoteAudioStats extends Equatable {
  /// Заметка, к которой привязан оригинал.
  final NoteEntity note;

  /// Размер файла записи в байтах.
  final int bytes;

  /// Длительность записи.
  final Duration duration;

  const NoteAudioStats({
    required this.note,
    required this.bytes,
    required this.duration,
  });

  @override
  List<Object?> get props => [note, bytes, duration];
}
