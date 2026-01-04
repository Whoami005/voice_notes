part of 'app_failure.dart';

/// Database-specific failures for presentation layer.
///
/// Use [DbFailure.from] to convert [DbException] to a user-safe failure.
/// Messages are automatically adjusted based on [kDebugMode]:
/// - Debug: detailed info with identifiers
/// - Release: generic user-friendly messages

sealed class DbFailure extends AppFailure {
  const DbFailure(super.message);

  /// Convert [DbException] to [DbFailure]
  static DbFailure from(DbException e) => switch (e) {
    EntityNotFoundException() => EntityNotFoundFailure(
      type: e.type,
      identifier: e.identifier,
    ),
  };
}

/// Failure when an entity is not found in the database
final class EntityNotFoundFailure extends DbFailure {
  final EntityType type;
  final String identifier;

  EntityNotFoundFailure({required this.type, required this.identifier})
    : super(_buildMessage(type, identifier));

  static String _buildMessage(EntityType type, String id) {
    if (kDebugMode) return '${type.displayName} не найден (id: $id)';

    return 'Данные не найдены';
  }

  @override
  List<Object?> get props => [message, type, identifier];
}
