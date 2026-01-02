import 'package:flutter/material.dart';
import 'package:voice_notes/feature/data/local/models/folder_object.dart';
import 'package:voice_notes/feature/domain/entities/folder_entity.dart';
import 'package:voice_notes/feature/domain/entities/icon_ref_entity.dart';

abstract final class FolderMapper {
  /// Конвертирует entity в domain модель.
  /// notesCount нужно передавать отдельно (через query.count()).
  static FolderEntity toDomain(FolderObject e) {
    return FolderEntity(
      uid: e.uid,
      name: e.name,
      description: e.description,
      color: Color(e.colorValue),
      icon:
          IconRefEntity.deserialize(e.iconRef) ??
          MaterialIconRefEntity(Icons.folder.codePoint),
      notesCount: e.notes.length,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  static FolderObject toEntity(FolderEntity f, {int id = 0}) {
    return FolderObject(
      id: id,
      uid: f.uid,
      name: f.name,
      description: f.description,
      colorValue: f.color.toARGB32(),
      iconRef: f.icon.serialize(),
      createdAt: f.createdAt,
      updatedAt: f.updatedAt,
    );
  }

  /// Обновляет существующую entity значениями из domain модели.
  static void updateEntity(FolderObject entity, FolderEntity folder) {
    entity
      ..name = folder.name
      ..description = folder.description
      ..colorValue = folder.color.toARGB32()
      ..iconRef = folder.icon.serialize()
      ..updatedAt = folder.updatedAt;
  }

  static List<FolderEntity> toDomainList(List<FolderObject> objects) => [
    for (final obj in objects) FolderMapper.toDomain(obj),
  ];
}
