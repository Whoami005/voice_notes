import 'dart:ui';

import 'package:voice_notes/feature/data/local/models/tag_object.dart';
import 'package:voice_notes/feature/domain/entities/tag_entity.dart';

abstract final class TagMapper {
  static TagEntity toDomain(TagObject e) {
    return TagEntity(
      name: e.name,
      color: e.colorValue != null ? Color(e.colorValue!) : null,
      createdAt: e.createdAt,
    );
  }

  static TagObject toEntity(TagEntity t) {
    return TagObject(
      name: t.name.toLowerCase().trim(),
      colorValue: t.color?.toARGB32(),
      createdAt: t.createdAt,
    );
  }

  static List<TagEntity> toDomainList(List<TagObject> entities) {
    return [for (final e in entities) toDomain(e)];
  }
}
