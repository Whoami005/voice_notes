import 'package:equatable/equatable.dart';

/// Абстракция иконки для хранения в БД.
/// Формат сериализации: "type:value"
sealed class IconRefEntity extends Equatable {
  const IconRefEntity();

  /// Сериализует в строку для хранения в БД.
  String serialize();

  /// Десериализует строку из БД в IconRefEntity.
  static IconRefEntity? deserialize(String value) {
    final separatorIndex = value.indexOf(':');
    if (separatorIndex == -1) return null;

    final type = value.substring(0, separatorIndex);
    final data = value.substring(separatorIndex + 1);

    return switch (type) {
      'material' => _parseMaterialIcon(data),
      'svg' => _parseSvgIcon(data),
      'photo' => _parsePhotoIcon(data),
      _ => null,
    };
  }

  static MaterialIconRefEntity? _parseMaterialIcon(String data) {
    return MaterialIconRefEntity.deserialize(data);
  }

  static SvgIconRefEntity? _parseSvgIcon(String data) {
    if (data.isEmpty) return null;

    return SvgIconRefEntity(data);
  }

  static PhotoIconRefEntity? _parsePhotoIcon(String data) {
    if (data.isEmpty) return null;

    return PhotoIconRefEntity(data);
  }
}

enum MaterialIconKey {
  folder('folder'),
  work('work'),
  book('book'),
  star('star'),
  favorite('favorite'),
  musicNote('music_note'),
  cameraAlt('camera_alt'),
  code('code');

  final String storageKey;

  const MaterialIconKey(this.storageKey);

  static MaterialIconKey? fromStorage(String value) {
    for (final key in MaterialIconKey.values) {
      if (key.storageKey == value) return key;
    }

    return null;
  }
}

/// Material Design иконка по стабильному ключу.
final class MaterialIconRefEntity extends IconRefEntity {
  static const MaterialIconRefEntity folder = MaterialIconRefEntity(
    MaterialIconKey.folder,
  );
  static const MaterialIconRefEntity work = MaterialIconRefEntity(
    MaterialIconKey.work,
  );
  static const MaterialIconRefEntity book = MaterialIconRefEntity(
    MaterialIconKey.book,
  );
  static const MaterialIconRefEntity star = MaterialIconRefEntity(
    MaterialIconKey.star,
  );
  static const MaterialIconRefEntity favorite = MaterialIconRefEntity(
    MaterialIconKey.favorite,
  );
  static const MaterialIconRefEntity musicNote = MaterialIconRefEntity(
    MaterialIconKey.musicNote,
  );
  static const MaterialIconRefEntity cameraAlt = MaterialIconRefEntity(
    MaterialIconKey.cameraAlt,
  );
  static const MaterialIconRefEntity code = MaterialIconRefEntity(
    MaterialIconKey.code,
  );

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

  final MaterialIconKey key;

  const MaterialIconRefEntity(this.key);

  static MaterialIconRefEntity? deserialize(String value) {
    final key = MaterialIconKey.fromStorage(value);
    if (key == null) return null;

    return _fromKey(key);
  }

  @override
  String serialize() => 'material:${key.storageKey}';

  @override
  List<Object?> get props => [key];

  static MaterialIconRefEntity _fromKey(MaterialIconKey key) => switch (key) {
    MaterialIconKey.folder => folder,
    MaterialIconKey.work => work,
    MaterialIconKey.book => book,
    MaterialIconKey.star => star,
    MaterialIconKey.favorite => favorite,
    MaterialIconKey.musicNote => musicNote,
    MaterialIconKey.cameraAlt => cameraAlt,
    MaterialIconKey.code => code,
  };
}

/// SVG иконка по asset-пути.
final class SvgIconRefEntity extends IconRefEntity {
  final String assetPath;

  const SvgIconRefEntity(this.assetPath);

  @override
  String serialize() => 'svg:$assetPath';

  @override
  List<Object?> get props => [assetPath];
}

/// Фото пользователя как иконка папки.
/// Хранит путь к файлу в локальном хранилище.
final class PhotoIconRefEntity extends IconRefEntity {
  final String filePath;

  const PhotoIconRefEntity(this.filePath);

  @override
  String serialize() => 'photo:$filePath';

  @override
  List<Object?> get props => [filePath];
}
