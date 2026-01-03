import 'package:dio/dio.dart';

sealed class AppException implements Exception {
  const AppException();

  /// Обработчик DioException → AppException
  static AppException fromDio(DioException e) {
    // Порядок важен: сначала проверяем сеть, потом сервер
    return NetworkException.tryParse(e) ??
        ServerException.tryParse(e) ??
        const UnknownException();
  }

  /// Выбросить с сохранением stack trace
  static Never throwFromDio(DioException error, StackTrace stackTrace) {
    Error.throwWithStackTrace(fromDio(error), stackTrace);
  }

  /// Выполняет запрос без парсинга (для void, простых типов)
  static Future<T> guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e, s) {
      throwFromDio(e, s);
    }
  }

  /// Выполняет запрос с парсингом ответа
  /// Разделяет сетевые ошибки и ошибки парсинга
  static Future<T> guardParse<T, D>(
    Future<D> Function() request,
    T Function(D data) parser,
  ) async {
    // 1. Сетевой запрос
    try {
      final response = await request();

      return FormatException.parseModel(() => parser(response));
    } on DioException catch (e, s) {
      throwFromDio(e, s);
    }
  }
}

final class ServerException extends AppException {
  final int code;
  final String error;

  const ServerException({required this.code, required this.error});

  /// Дефолтная ошибка сервера (заглушка)
  const ServerException.unknown() : code = -1, error = 'Ошибка сервера';

  /// Пытается распарсить DioException как серверную ошибку
  static ServerException? tryParse(DioException e) {
    // Обработка HTTP статус кодов без тела
    final statusCode = e.response?.statusCode;

    if (statusCode != null && statusCode >= 400) {
      return ServerException(
        code: statusCode,
        error: _messageFromStatusCode(statusCode),
      );
    }

    return null;
  }

  static String _messageFromStatusCode(int code) => switch (code) {
    400 => 'Неверный запрос',
    401 => 'Необходима авторизация',
    403 => 'Доступ запрещён',
    404 => 'Не найдено',
    422 => 'Ошибка валидации',
    429 => 'Слишком много запросов',
    >= 500 => 'Ошибка сервера',
    _ => 'Что-то пошло не так',
  };
}

enum NetworkExceptionType { noConnection, timeout, ssl }

final class NetworkException extends AppException {
  final NetworkExceptionType type;

  const NetworkException(this.type);

  const NetworkException.noConnection()
    : type = NetworkExceptionType.noConnection;

  const NetworkException.timeout() : type = NetworkExceptionType.timeout;

  /// Пытается распарсить DioException как сетевую ошибку
  static NetworkException? tryParse(DioException e) {
    final type = switch (e.type) {
      DioExceptionType.connectionError => NetworkExceptionType.noConnection,
      DioExceptionType.connectionTimeout => NetworkExceptionType.timeout,
      DioExceptionType.sendTimeout => NetworkExceptionType.timeout,
      DioExceptionType.receiveTimeout => NetworkExceptionType.timeout,
      DioExceptionType.badCertificate => NetworkExceptionType.ssl,
      _ => null,
    };

    return type != null ? NetworkException(type) : null;
  }
}

enum FormatExceptionType { json, model }

final class FormatException extends AppException {
  final FormatExceptionType type;
  final String? details;

  const FormatException(this.type, [this.details]);

  const FormatException.json([this.details]) : type = FormatExceptionType.json;

  const FormatException.model([String? modelName])
    : type = FormatExceptionType.model,
      details = modelName;

  /// Оборачивает операцию парсинга и выбрасывает FormatException при ошибке
  static T parseJson<T>(T Function() parser, [String? context]) {
    try {
      return parser();
    } catch (e) {
      throw FormatException.json(context ?? e.toString());
    }
  }

  /// Оборачивает создание модели и выбрасывает FormatException при ошибке
  static T parseModel<T>(T Function() parser, [String? modelName]) {
    try {
      return parser();
    } catch (e, s) {
      Error.throwWithStackTrace(
        FormatException.model(modelName ?? T.toString()),
        s,
      );
    }
  }
}

final class CustomException extends AppException {
  final String message;

  const CustomException(this.message);

  // Фабричные конструкторы для частых случаев
  const CustomException.validation(String field)
    : this('Проверьте поле: $field');

  const CustomException.empty(String what) : this('$what не может быть пустым');

  const CustomException.notFound(String what) : this('$what не найден');
}

final class UnknownException extends AppException {
  final Object? originalError;

  const UnknownException([this.originalError]);
}
