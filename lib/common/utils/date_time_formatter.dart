import 'package:intl/intl.dart';

abstract final class DateTimeFormatter {
  static String full(DateTime dateTime, {required String localeCode}) {
    final formatter = DateFormat('dd MMMM yyyy, HH:mm', localeCode);

    return formatter.format(dateTime);
  }

  static String time(DateTime dateTime) {
    final formatter = DateFormat('HH:mm');

    return formatter.format(dateTime);
  }
}
