import 'package:equatable/equatable.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';

/// Статистика аудиохранилища в разрезе одной папки.
class FolderStorageStats extends Equatable {
  /// Папка, к которой принадлежит статистика. Null — группа «Без папки».
  final FolderEntity? folder;

  /// Суммарный размер аудио этой папки в байтах.
  final int bytes;

  /// Количество сохранённых оригинальных записей в папке.
  final int count;

  /// Суммарная длительность аудио этой папки.
  final Duration totalDuration;

  const FolderStorageStats({
    required this.bytes,
    required this.count,
    required this.totalDuration,
    this.folder,
  });

  @override
  List<Object?> get props => [folder, bytes, count, totalDuration];
}
