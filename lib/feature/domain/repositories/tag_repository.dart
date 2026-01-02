import 'dart:ui';

import 'package:voice_notes/feature/domain/entities/tag_entity.dart';

/// Репозиторий для управления тегами
abstract interface class TagRepository {
  /// Получить все теги
  Future<List<TagEntity>> getAll();

  /// Получить тег по имени (case-insensitive)
  Future<TagEntity?> getByName(String name);

  /// Создать новый тег
  Future<TagEntity> create({required String name, Color? color});

  /// Получить или создать тег по имени
  Future<TagEntity> getOrCreate({required String name, Color? color});

  /// Удалить тег по UID
  Future<void> delete(String name);

  /// Стрим всех тегов с реактивными обновлениями
  Stream<List<TagEntity>> watchAll();
}
