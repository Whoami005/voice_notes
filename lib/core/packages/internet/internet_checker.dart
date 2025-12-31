import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Утилита для проверки подключения к интернету
class InternetChecker {
  const InternetChecker._();

  static final InternetConnection _connection = InternetConnection();

  /// Проверить наличие подключения к интернету
  /// Выполняет реальную проверку доступности сети (не только WiFi/Mobile статус)
  static Future<bool> hasConnection() => _connection.hasInternetAccess;

  /// Стрим для отслеживания изменений статуса подключения
  static Stream<InternetStatus> get onStatusChange =>
      _connection.onStatusChange;

  /// Проверить, подключен ли в данный момент
  static Future<bool> get isConnected async {
    final status = await _connection.internetStatus;
    return status == InternetStatus.connected;
  }
}
