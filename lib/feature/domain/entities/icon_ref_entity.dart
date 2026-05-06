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
      // TODO(W): 'svg' => SvgIconRefEntity(data),
      // TODO(W): 'asset' => AssetIconRefEntity(data),
      // TODO(W): 'photo' => PhotoIconRefEntity(data),
      _ => null,
    };
  }

  static MaterialIconRefEntity? _parseMaterialIcon(String data) {
    return MaterialIconRefEntity.deserialize(data);
  }
}

/// Material Design иконка по стабильному ключу.
class MaterialIconRefEntity extends IconRefEntity {
  static const MaterialIconRefEntity folder = MaterialIconRefEntity._('folder');
  static const MaterialIconRefEntity work = MaterialIconRefEntity._('work');
  static const MaterialIconRefEntity book = MaterialIconRefEntity._('book');
  static const MaterialIconRefEntity star = MaterialIconRefEntity._('star');
  static const MaterialIconRefEntity favorite = MaterialIconRefEntity._(
    'favorite',
  );
  static const MaterialIconRefEntity musicNote = MaterialIconRefEntity._(
    'music_note',
  );
  static const MaterialIconRefEntity cameraAlt = MaterialIconRefEntity._(
    'camera_alt',
  );
  static const MaterialIconRefEntity code = MaterialIconRefEntity._('code');

  static const List<MaterialIconRefEntity> values = [
    folder,
    work,
    book,
    star,
    favorite,
    musicNote,
    cameraAlt,
    code,
  ];

  final String iconKey;

  const MaterialIconRefEntity._(this.iconKey);

  static MaterialIconRefEntity? deserialize(String value) {
    final icon = _fromKey(value);
    if (icon != null) return icon;

    final codePoint = int.tryParse(value);
    if (codePoint == null) return null;

    return _fromLegacyCodePoint(codePoint);
  }

  @override
  String serialize() => 'material:$iconKey';

  @override
  IconData toIconData() => switch (iconKey) {
    'folder' => Icons.folder,
    'work' => Icons.work,
    'book' => Icons.book,
    'star' => Icons.star,
    'favorite' => Icons.favorite,
    'music_note' => Icons.music_note,
    'camera_alt' => Icons.camera_alt,
    'code' => Icons.code,
    _ => Icons.folder,
  };

  @override
  List<Object?> get props => [iconKey];

  static MaterialIconRefEntity? _fromKey(String key) => switch (key) {
    'folder' => folder,
    'work' => work,
    'book' => book,
    'star' => star,
    'favorite' => favorite,
    'music_note' => musicNote,
    'camera_alt' => cameraAlt,
    'code' => code,
    _ => null,
  };

  static MaterialIconRefEntity? _fromLegacyCodePoint(int codePoint) {
    if (codePoint == Icons.folder.codePoint) return folder;
    if (codePoint == Icons.work.codePoint) return work;
    if (codePoint == Icons.book.codePoint) return book;
    if (codePoint == Icons.star.codePoint) return star;
    if (codePoint == Icons.favorite.codePoint) return favorite;
    if (codePoint == Icons.music_note.codePoint) return musicNote;
    if (codePoint == Icons.camera_alt.codePoint) return cameraAlt;
    if (codePoint == Icons.code.codePoint) return code;

    return null;
  }
}

// -----------------------------------------------------------------------------
// TODO(W): Реализовать когда понадобится поддержка кастомных иконок
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
