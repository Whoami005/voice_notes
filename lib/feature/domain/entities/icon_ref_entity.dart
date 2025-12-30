import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Абстракция иконки для хранения в БД.
/// Формат сериализации: "type:value"
sealed class IconRefEntity extends Equatable {
  const IconRefEntity();

  /// Сериализует в строку для хранения в БД.
  String serialize();

  /// Конвертирует в IconData для отображения.
  /// Возвращает null для типов, не поддерживающих IconData (SVG, Asset).
  IconData? toIconData();

  /// Десериализует строку из БД в IconRefEntity.
  static IconRefEntity? deserialize(String value) {
    final separatorIndex = value.indexOf(':');
    if (separatorIndex == -1) return null;

    final type = value.substring(0, separatorIndex);
    final data = value.substring(separatorIndex + 1);

    return switch (type) {
      'material' => _parseMaterialIcon(data),
      // TODO: 'svg' => SvgIconRefEntity(data),
      // TODO: 'asset' => AssetIconRefEntity(data),
      // TODO: 'photo' => PhotoIconRefEntity(data),
      _ => null,
    };
  }

  static MaterialIconRefEntity? _parseMaterialIcon(String data) {
    final codePoint = int.tryParse(data);
    if (codePoint == null) return null;

    return MaterialIconRefEntity(codePoint);
  }
}

/// Material Design иконка (codePoint).
class MaterialIconRefEntity extends IconRefEntity {
  final int codePoint;

  const MaterialIconRefEntity(this.codePoint);

  /// Создаёт из Flutter IconData.
  factory MaterialIconRefEntity.fromIconData(IconData icon) {
    return MaterialIconRefEntity(icon.codePoint);
  }

  @override
  String serialize() => 'material:$codePoint';

  @override
  IconData toIconData() => IconData(codePoint, fontFamily: 'MaterialIcons');

  @override
  List<Object?> get props => [codePoint];
}

// -----------------------------------------------------------------------------
// TODO: Реализовать когда понадобится поддержка кастомных иконок
// -----------------------------------------------------------------------------

// /// SVG иконка (путь к asset).
// /// Требует пакет flutter_svg для рендеринга.
// class SvgIconRefEntity extends IconRefEntity {
//   final String path;
//   const SvgIconRefEntity(this.path);
//
//   @override
//   String serialize() => 'svg:$path';
//
//   @override
//   IconData? toIconData() => null;
// }

// /// Растровое изображение (PNG/JPG) как иконка.
// class AssetIconRefEntity extends IconRefEntity {
//   final String path;
//   const AssetIconRefEntity(this.path);
//
//   @override
//   String serialize() => 'asset:$path';
//
//   @override
//   IconData? toIconData() => null;
// }

// /// Фото пользователя как иконка папки.
// /// Хранит путь к файлу в локальном хранилище.
// class PhotoIconRefEntity extends IconRefEntity {
//   final String path;
//   const PhotoIconRefEntity(this.path);
//
//   @override
//   String serialize() => 'photo:$path';
//
//   @override
//   IconData? toIconData() => null;
// }
