import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:voice_notes/core/error/app_exception.dart';

sealed class AppFailure extends Equatable {
  final String message;

  const AppFailure(this.message);

  @override
  List<Object?> get props => [message];

  /// Основной обработчик: любая ошибка → AppFailure
  static AppFailure from(Object error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('AppFailure $error: $stackTrace');
    }

    return switch (error) {
      final AppException e => _fromException(e),
      final AppFailure f => f,
      _ => UnknownFailure(error.toString()),
    };
  }

  static AppFailure _fromException(AppException e) {
    return switch (e) {
      ServerException() => ServerFailure(e.error, code: e.code),
      NetworkException() => NetworkFailure.fromType(e.type),
      FormatException() => FormatFailure(details: e.details),
      UnknownException() => const UnknownFailure(),
    };
  }
}

final class ServerFailure extends AppFailure {
  final int code;

  const ServerFailure(super.message, {required this.code});

  /// Дефолтная серверная ошибка (заглушка)
  const ServerFailure.unknown()
    : code = -1,
      super('Ошибка сервера. Попробуйте позже');

  /// Проверки по коду
  bool get isUnauthorized => code == 401;

  bool get isForbidden => code == 403;

  bool get isNotFound => code == 404;

  bool get isValidation => code == 422;

  bool get isRateLimit => code == 429;

  @override
  List<Object?> get props => [message, code];
}

final class NetworkFailure extends AppFailure {
  final NetworkFailureType type;

  const NetworkFailure(super.message, this.type);

  const NetworkFailure.noConnection()
    : type = NetworkFailureType.noConnection,
      super('Отсутствует интернет соединение');

  const NetworkFailure.timeout()
    : type = NetworkFailureType.timeout,
      super('Превышено время ожидания');

  const NetworkFailure.ssl()
    : type = NetworkFailureType.ssl,
      super('Ошибка безопасности соединения');

  factory NetworkFailure.fromType(NetworkExceptionType type) {
    return switch (type) {
      NetworkExceptionType.noConnection => const NetworkFailure.noConnection(),
      NetworkExceptionType.timeout => const NetworkFailure.timeout(),
      NetworkExceptionType.ssl => const NetworkFailure.ssl(),
    };
  }

  bool get isNoConnection => type == NetworkFailureType.noConnection;

  bool get isTimeout => type == NetworkFailureType.timeout;

  @override
  List<Object?> get props => [message, type];
}

enum NetworkFailureType { noConnection, timeout, ssl }

final class FormatFailure extends AppFailure {
  final String? details;

  @override
  String get message =>
      kDebugMode ? '${super.message} $details' : super.message;

  const FormatFailure({this.details}) : super('Ошибка обработки данных');
}

/// Кастомная ошибка для ручного выброса в стейт менеджере
/// Используется для бизнес-логики и валидации на уровне презентации
final class CustomFailure extends AppFailure {
  const CustomFailure(super.message);

  // Фабричные конструкторы для частых случаев
  const CustomFailure.validation(String field)
    : super('Проверьте поле: $field');

  const CustomFailure.empty(String what) : super('$what не может быть пустым');

  const CustomFailure.notFound(String what) : super('$what не найден');
}

final class UnknownFailure extends AppFailure {
  @override
  String get message => kDebugMode ? super.message : 'Что-то пошло не так';

  const UnknownFailure([super.message = 'Что-то пошло не так']);
}

/// Ошибка при скачивании модели
final class DownloadFailure extends AppFailure {
  const DownloadFailure(super.message);

  const DownloadFailure.cancelled() : super('Скачивание отменено');

  const DownloadFailure.extractionFailed()
    : super('Не удалось распаковать модель');
}

/// Ошибка при проверке хранилища
final class StorageFailure extends AppFailure {
  final int? requiredBytes;
  final int? availableBytes;

  const StorageFailure(
    super.message, {
    this.requiredBytes,
    this.availableBytes,
  });

  const StorageFailure.insufficientSpace({
    this.requiredBytes,
    this.availableBytes,
  }) : super('Недостаточно места на устройстве');

  const StorageFailure.cannotCheck()
    : requiredBytes = null,
      availableBytes = null,
      super('Не удалось проверить свободное место');
}
