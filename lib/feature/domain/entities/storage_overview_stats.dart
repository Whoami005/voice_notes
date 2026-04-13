import 'package:equatable/equatable.dart';

/// Общая статистика аудиохранилища приложения.
class StorageOverviewStats extends Equatable {
  /// Суммарный размер всех сохранённых оригиналов в байтах.
  final int totalBytes;

  /// Количество сохранённых оригинальных записей.
  final int totalCount;

  const StorageOverviewStats({
    required this.totalBytes,
    required this.totalCount,
  });

  const StorageOverviewStats.empty() : totalBytes = 0, totalCount = 0;

  bool get isEmpty => totalCount == 0;

  @override
  List<Object?> get props => [totalBytes, totalCount];
}
