import 'package:disk_space_2/disk_space_2.dart';

/// Утилита для проверки свободного места на устройстве
class StorageChecker {
  const StorageChecker._();

  /// Получить свободное место в байтах
  /// Возвращает null если не удалось получить информацию
  static Future<int?> getAvailableSpace() async {
    final freeSpaceMB = await DiskSpace.getFreeDiskSpace;
    if (freeSpaceMB == null) return null;

    return (freeSpaceMB * 1024 * 1024).toInt();
  }

  /// Получить общий объем хранилища в байтах
  static Future<int?> getTotalSpace() async {
    final totalSpaceMB = await DiskSpace.getTotalDiskSpace;
    if (totalSpaceMB == null) return null;

    return (totalSpaceMB * 1024 * 1024).toInt();
  }

  /// Проверить, достаточно ли места для скачивания
  /// [requiredBytes] - необходимое количество байт
  /// Возвращает true если места достаточно
  static Future<bool> hasEnoughSpace(int requiredBytes) async {
    final availableBytes = await getAvailableSpace();
    if (availableBytes == null) return false;

    return availableBytes >= requiredBytes;
  }

  /// Проверить место с учетом буфера (10%)
  /// [requiredBytes] - базовое количество байт
  static Future<bool> hasEnoughSpaceWithBuffer(int requiredBytes) async {
    final withBuffer = (requiredBytes * 1.1).toInt();

    return hasEnoughSpace(withBuffer);
  }
}
