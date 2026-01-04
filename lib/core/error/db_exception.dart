part of 'app_exception.dart';

/// Entity types for database operations
enum EntityType {
  folder,
  note,
  tag,
  model;

  /// Returns the Russian name for this entity type
  String get displayName => switch (this) {
    EntityType.folder => 'Папка',
    EntityType.note => 'Заметка',
    EntityType.tag => 'Тег',
    EntityType.model => 'Модель',
  };
}

/// Base class for all database exceptions
sealed class DbException implements AppException {
  const DbException();
}

/// Exception thrown when an entity is not found in the database
final class EntityNotFoundException extends DbException {
  final EntityType type;
  final String identifier;

  const EntityNotFoundException({required this.type, required this.identifier});

  // Shortcuts for common entity types
  const EntityNotFoundException.folder(String uid)
    : type = EntityType.folder,
      identifier = uid;

  const EntityNotFoundException.note(String uid)
    : type = EntityType.note,
      identifier = uid;

  const EntityNotFoundException.tag(String name)
    : type = EntityType.tag,
      identifier = name;

  const EntityNotFoundException.model(String modelId)
    : type = EntityType.model,
      identifier = modelId;

  @override
  String toString() => '${type.name} not found: $identifier';
}

/// Extension for convenient null-check with throw
extension EntityGuard<T> on T? {
  /// Throws [EntityNotFoundException] if this is null
  T orThrowNotFound(EntityType type, String identifier) {
    if (this == null) {
      throw EntityNotFoundException(type: type, identifier: identifier);
    }
    return this as T;
  }
}
