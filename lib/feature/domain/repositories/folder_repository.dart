import 'dart:ui';

import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';

/// Репозиторий для управления папками
abstract interface class FolderRepository {
  /// Получить все папки, отсортированные по updatedAt DESC
  Future<List<FolderEntity>> getAll();

  /// Получить папку по UID
  Future<FolderEntity> getByUid(String uid);

  /// Создать новую папку
  Future<FolderEntity> create({
    required String name,
    required Color color,
    required IconRefEntity icon,
    String? description,
  });

  /// Обновить существующую папку
  Future<FolderEntity> update(FolderEntity folder);

  /// Удалить папку по UID
  Future<void> delete(String uid);

  /// Удалить папку вместе со всеми заметками (каскадное удаление)
  Future<void> deleteWithNotes(String uid);

  /// Стрим всех папок с реактивными обновлениями
  Stream<List<FolderEntity>> watchAll();

  /// Стрим папки по UID с реактивными обновлениями
  Stream<FolderEntity?> watchByUid(String uid);
}
